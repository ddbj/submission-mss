module Authentication
  extend ActiveSupport::Concern

  BEARER = /\ABearer\s+(\S+)\z/i

  included do
    # A request carrying a token speaks for itself and nothing else: whatever
    # cookie came along with it is neither consulted nor renewed.
    before_action :skip_session_for_bearer, prepend: true

    # A write from a session that has since gone is a request from nobody, not a
    # malformed one -- the token it carries was good, and there is simply
    # nothing left to check it against. Said plainly, the frontend knows to ask
    # them to sign in again; called unprocessable, it can only apologise.
    rescue_from ActionController::InvalidAuthenticityToken do |e|
      raise e if session[:user_id]

      authenticate!
    end
  end

  def current_user
    return @current_user if defined?(@current_user)

    @current_user = bearer_request? ? bearer_user : User.find_by(id: session[:user_id])
  end

  def authenticate!
    return if current_user

    render json: {
      error: 'Unauthorized'
    }, status: :unauthorized
  end

  private

  # Another client of the realm calling on a submitter's behalf. Any other
  # scheme is not ours to read, and leaves the request to the session.
  def bearer_request?
    !bearer_token.nil?
  end

  def bearer_token
    return @bearer_token if defined?(@bearer_token)

    @bearer_token = request.authorization.to_s[BEARER, 1]
  end

  # Verified once however many times we are asked; nil if it does not verify.
  def bearer_claims
    return @bearer_claims if defined?(@bearer_claims)

    @bearer_claims = begin
      BearerToken.verify(token: bearer_token)
    rescue BearerToken::Invalid => e
      Rails.logger.info "Bearer token rejected: #{e.message}"

      nil
    end
  end

  def bearer_user
    return nil unless (claims = bearer_claims)

    uid   = claims['preferred_username']
    email = claims['email'].presence
    email = nil unless email.is_a?(String)
    user  = User.find_or_initialize_by(uid:)

    # Without an address there is no one to tell about their submission, and
    # the token is all we would know them by.
    return nil if user.new_record? && email.nil?

    user.email = email if email
    user.save! if user.changed?

    user
  rescue ActiveRecord::RecordNotUnique
    # Two first requests from the same newcomer at once, and the other won.
    User.find_by(uid:)
  end

  # A page on another origin cannot attach an Authorization header without a
  # preflight, which CORS answers only for our own frontend -- and that frontend
  # does not send one. So a token stands in for the CSRF token; one that does
  # not verify fails authentication instead.
  def verified_request?
    super || bearer_request?
  end

  def skip_session_for_bearer
    request.session_options[:skip] = true if bearer_request?
  end
end
