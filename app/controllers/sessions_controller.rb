class SessionsController < ApplicationController
  skip_before_action :authenticate!, only: %i[create failure]

  # OmniAuth hands over whatever request failed, which is the POST that starts a
  # login when the provider cannot be reached. Failing changes nothing here.
  skip_forgery_protection only: :failure

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

  # Why a login may not go through that is the submitter's to see to: they
  # declined, or took too long over it. Everything else is ours, and would
  # otherwise go unnoticed until nobody could sign in -- a client the provider
  # no longer recognises, a session that does not survive the round trip.
  SUBMITTERS_OWN_FAILURES = %w[
    access_denied
    login_required
    consent_required
    interaction_required
    invalid_grant
    missing_code
  ]

  # Called by OmniAuth when a login does not go through. There is nothing to
  # tell the frontend that it will not work out for itself: it asks who is
  # signed in on the way in, and will be told nobody.
  def failure
    error = request.env['omniauth.error']
    type  = request.env['omniauth.error.type'].to_s

    if error && !SUBMITTERS_OWN_FAILURES.include?(type)
      # A state that does not match is also what the back button, or two
      # logins in two tabs, comes to.
      Rails.error.report error, severity: type == 'csrf_detected' ? :warning : :error, context: {type: type.truncate(100)}
    end

    redirect_to_frontend
  end

  private

  def redirect_to_frontend
    redirect_to Rails.application.config_for(:app).web_url!, allow_other_host: true
  end
end
