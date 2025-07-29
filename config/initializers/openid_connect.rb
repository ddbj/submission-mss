OpenIDConnect.logger = Rails.logger
Rack::OAuth2.logger  = Rails.logger
WebFinger.logger     = Rails.logger
SWD.logger           = Rails.logger

url = Rails.application.config_for(:keycloak).url!

SWD.url_builder = URI::HTTP if URI.parse(url).scheme == 'http'
