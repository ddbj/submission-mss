if dsn = ENV['SENTRY_DSN']
  Sentry.init do |config|
    config.dsn                = dsn
    config.breadcrumbs_logger = [:active_support_logger, :http_logger]
  end
end
