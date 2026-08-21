module Authentication
  extend ActiveSupport::Concern

  included do
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

    @current_user = User.find_by(id: session[:user_id])
  end

  def authenticate!
    return if current_user

    render json: {
      error: 'Unauthorized'
    }, status: :unauthorized
  end
end
