module Authentication
  include ActionController::HttpAuthentication::Token::ControllerMethods

  def current_user
    return @current_user if defined?(@current_user)

    @current_user = authenticate_with_http_token {|token|
      Rails.error.handle(JWT::DecodeError) {
        payload, = JWT.decode(token, Rails.application.secret_key_base, true, algorithm: 'HS512')

        User.find_by(id: payload.fetch('user_id'))
      }
    }
  end

  def authenticate!
    return if current_user

    render json: {
      error: 'Unauthorized'
    }, status: :unauthorized
  end
end
