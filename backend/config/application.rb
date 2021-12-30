require_relative 'boot'

require 'rails'
require 'active_model/railtie'
require 'active_job/railtie'
require 'active_record/railtie'
require 'active_storage/engine'
require 'action_controller/railtie'
require 'action_mailer/railtie'
require 'action_view/railtie'

Bundler.require *Rails.groups

module MssForm
  class Application < Rails::Application
    config.load_defaults 7.0

    config.active_job.queue_adapter   = :sidekiq
    config.active_storage.draw_routes = false
    config.api_only                   = true
    config.cache_store                = :mem_cache_store
    config.time_zone                  = ENV.fetch('TZ')
  end
end
