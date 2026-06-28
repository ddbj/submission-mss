Sentry.init do |config|
  config.breadcrumbs_logger = [:active_support_logger, :http_logger]
  config.dsn                = Rails.application.config_for(:app).sentry_dsn
end
