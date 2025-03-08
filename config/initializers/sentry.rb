Sentry.init do |config|
  config.breadcrumbs_logger = [ :active_support_logger, :http_logger ]
  config.dsn                = Rails.application.credentials.sentry_dsn
end
