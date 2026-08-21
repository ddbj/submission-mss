require_relative 'boot'

require 'rails'
# Pick the frameworks you want:
require 'active_model/railtie'
require 'active_job/railtie'
require 'active_record/railtie'
require 'active_storage/engine'
require 'action_controller/railtie'
require 'action_mailer/railtie'
# require "action_mailbox/engine"
# require "action_text/engine"
require 'action_view/railtie'
# require "action_cable/engine"
# require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module MSSForm
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.1

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    # Only loads a smaller set of middleware suitable for API only apps.
    # Middleware like session, flash, cookies can be added back manually.
    # Skip views, helpers and assets when generating a new resource.
    config.api_only = true

    config.action_mailer.delivery_job                 = 'MailDeliveryJob'
    config.active_storage.draw_routes                 = false
    config.active_storage.variant_processor           = :disabled
    config.mission_control.jobs.base_controller_class = 'ActionController::Base'
    config.time_zone                                  = 'Asia/Tokyo'

    # An API-only application is not given a session, and this one needs one: it
    # is the whole of a submitter's credential. The options go here rather than
    # in config.session_options, which is read by the stack we do not have.
    # OmniAuth is added after this and has to be, since it writes the session
    # before sending the visitor to the provider.
    #
    # HttpOnly keeps the cookie away from any script that finds its way onto the
    # page, Lax keeps it off cross-site writes, and the expiry is carried inside
    # the encrypted cookie, so it holds however the browser is persuaded to keep
    # sending it.
    config.middleware.use ActionDispatch::Cookies

    config.middleware.use ActionDispatch::Session::CookieStore, **{
      key:          '_mssform',
      httponly:     true,
      same_site:    :lax,
      expire_after: 12.hours
    }
  end
end
