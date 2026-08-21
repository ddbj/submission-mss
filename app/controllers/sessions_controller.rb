class SessionsController < ApplicationController
  skip_before_action :authenticate!, only: %i[create failure]

  def create
    uid  = request.env.dig('omniauth.auth', 'extra', 'raw_info', 'preferred_username')
    user = User.find_or_initialize_by(uid:)

    user.update! email: request.env.dig('omniauth.auth', 'info', 'email')

    # Whatever the visitor arrived holding, they leave with a session of their
    # own, so nothing carried in from before this login can be spent after it.
    reset_session

    session[:user_id] = user.id

    redirect_to_frontend
  end

  def destroy
    reset_session

    head :no_content
  end

  # Sent here by OmniAuth when the provider turns a login down. There is nothing
  # to tell the frontend that it will not work out for itself: it asks who is
  # signed in on the way in, and will be told nobody.
  def failure
    redirect_to_frontend
  end

  private

  def redirect_to_frontend
    redirect_to Rails.application.config_for(:app).web_url!, allow_other_host: true
  end
end
