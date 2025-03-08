OpenIDConnect.logger = Rails.logger
Rack::OAuth2.logger  = Rails.logger
WebFinger.logger     = Rails.logger
SWD.logger           = Rails.logger

SWD.url_builder = URI::HTTP if URI.parse(Rails.application.config_for(:app).oidc_issuer_url!).scheme == "http"
