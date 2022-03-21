Sidekiq.configure_server do |config|
  config.death_handlers << ->(job, err) {
    ExceptionNotifier.notify_exception(err, data: {sidekiq: job})
  }
end
