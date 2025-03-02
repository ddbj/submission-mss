class AuthsController < ApplicationController
  skip_before_action :authenticate

  def self.oidc_config
    @oidc_config ||= OpenIDConnect::Discovery::Provider::Config.discover!(Rails.configuration.x.oidc_issuer_url)
  end

  def login
    state         = session[:state]         = generate_state
    code_verifier = session[:code_verifier] = generate_code_verifier

    code_challenge = calculate_code_challenge(code_verifier)

    redirect_to oidc_client.authorization_uri(
      scope:                 %w[openid email profile],
      prompt:                "login",
      state:,
      code_challenge:,
      code_challenge_method: "S256"
    ), allow_other_host: true
  end

  def callback
    state         = session.delete(:state)
    code_verifier = session.delete(:code_verifier)

    unless state == params.require(:state)
      render plain: "Error: state mismatch", status: :bad_request

      return
    end

    oidc_client.authorization_code = params.require(:code)

    access_token = oidc_client.access_token!(code_verifier:)
    userinfo     = access_token.userinfo!
    user         = User.find_or_initialize_by(uid: userinfo.preferred_username)

    user.update! email: userinfo.email

    cookies[:api_key] = user.api_key

    redirect_to ENV.fetch("WEB_URL"), allow_other_host: true
  rescue Rack::OAuth2::Client::Error => e
    render plain: "Error: #{e.message}", status: :bad_request
  end

  private

  def generate_state         = SecureRandom.urlsafe_base64(32)
  def generate_code_verifier = SecureRandom.urlsafe_base64(32)

  def calculate_code_challenge(code_verifier)
    Base64.urlsafe_encode64(
      OpenSSL::Digest::SHA256.digest(code_verifier),
      padding: false
    )
  end

  def oidc_client
    @oidc_client ||= OpenIDConnect::Client.new(
      identifier:             "mssform",
      redirect_uri:           callback_auth_url,
      jwks_uri:               self.class.oidc_config.jwks_uri,
      authorization_endpoint: self.class.oidc_config.authorization_endpoint,
      token_endpoint:         self.class.oidc_config.token_endpoint,
      userinfo_endpoint:      self.class.oidc_config.userinfo_endpoint
    )
  end
end
