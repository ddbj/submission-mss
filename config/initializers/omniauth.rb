OmniAuth.config.request_validation_phase = nil

keycloak     = Rails.application.config_for(:keycloak)
keycloak_url = URI.parse(keycloak.url!)

Rails.application.config.middleware.use OmniAuth::Builder do
  provider :openid_connect, **{
    name:      "keycloak",
    issuer:    URI.join(keycloak_url, "/realms/master").to_s,
    discovery: true,
    scope:     %i[openid email profile],
    prompt:    "login",

    client_options: {
      scheme:       keycloak_url.scheme,
      port:         keycloak_url.port,
      host:         keycloak_url.host,
      identifier:   keycloak.client_id,
      secret:       keycloak.client_secret,
      redirect_uri: URI.join(Rails.application.config_for(:app).app_url!, "/auth/keycloak/callback").to_s
    }
  }
end
