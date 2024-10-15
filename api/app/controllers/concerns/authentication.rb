module Authentication
  def current_user
    return @current_user if defined?(@current_user)

    @current_user = authenticate_with_http_token { |token|
      User.find_by(api_key: token)
    }
  end

  private

  def authenticate
    return if current_user

    render json: {
      error: "Unauthorized"
    }, status: :unauthorized
  end
end
