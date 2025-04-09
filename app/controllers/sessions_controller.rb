class SessionsController < ApplicationController
  skip_before_action :authenticate!, only: %i[create]

  def create
    uid  = request.env.dig("omniauth.auth", "extra", "raw_info", "preferred_username")
    user = User.find_or_initialize_by(uid:)

    user.update! email: request.env.dig("omniauth.auth", "info", "email")

    token = JWT.encode({ user_id: user.id }, Rails.application.secret_key_base, "HS512")

    url       = URI.join(Rails.application.config_for(:app).web_url!, "/login")
    url.query = URI.encode_www_form(token:)

    redirect_to url.to_s, allow_other_host: true
  end
end
