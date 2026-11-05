module Authentication
  extend ActiveSupport::Concern

  BEARER = /\ABearer\s+(\S+)\z/i

  included do
    # The actions a realm token is let in to; see allow_bearer.
    class_attribute :bearer_actions, instance_accessor: false, default: Set.new.freeze

    # A request carrying a token speaks for itself and nothing else: whatever
    # cookie came along with it is neither consulted nor renewed. The session
    # middleware reads this only when it commits, so it is in time from any
    # point in the request.
    before_action :skip_session_for_bearer

    # A write from a session that has since gone is a request from nobody, not a
    # malformed one -- the token it carries was good, and there is simply
    # nothing left to check it against. Said plainly, the frontend knows to ask
    # them to sign in again; called unprocessable, it can only apologise.
    rescue_from ActionController::InvalidAuthenticityToken do |e|
      raise e if session[:user_id]

      authenticate!
    end
  end

  class_methods do
    # Lets a realm token (see BearerToken) in to the given actions -- only
    # those another client needs on a submitter's behalf. Every other action
    # answers a request carrying a token with 401, whatever cookie came along.
    def allow_bearer(only:)
      self.bearer_actions = Array(only).to_set(&:to_s).freeze
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
    unless self.class.bearer_actions.include?(action_name)
      Rails.logger.info "Bearer token not accepted by #{self.class.name}##{action_name}"

      return nil
    end

    return nil unless (claims = bearer_claims)

    # Only a newcomer takes the token's address. An existing user's is the one
    # their own sign-in keeps up to date.
    User.from_claims!(uid: claims['preferred_username'], email: claims['email'])
  rescue User::IncompleteClaims => e
    Rails.logger.info "Bearer token rejected: #{e.message}"

    nil
  end

  # A page on another origin cannot attach an Authorization header without a
  # preflight, which CORS answers only for our own frontend -- and that frontend
  # does not send one. So a token stands in for the CSRF token; one that does
  # not verify fails authentication instead. Asked first, so that a request
  # with a token never reads the session for its CSRF token.
  def verified_request?
    bearer_request? || super
  end

  def skip_session_for_bearer
    request.session_options[:skip] = true if bearer_request?
  end
end
