Sentry.init do |config|
  config.breadcrumbs_logger = [:active_support_logger, :http_logger]
  config.dsn                = Rails.application.config_for(:app).sentry_dsn

  # Off by default in sentry-rails, which leaves Rails.error.report doing
  # nothing at all: there is no other subscriber, so anything reported that way
  # -- ours, and the worker thread errors Solid Queue reports for us -- is
  # written down nowhere and read by nobody.
  config.rails.register_error_subscriber = true
end
