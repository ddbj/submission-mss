OpenIDConnect.logger = Rails.logger
Rack::OAuth2.logger  = Rails.logger
WebFinger.logger     = Rails.logger
SWD.logger           = Rails.logger

SWD.url_builder = URI::HTTP if URI.parse(Rails.configuration.x.oidc_issuer_url).scheme == "http"
