# Be sure to restart your server when you modify this file.

# Avoid CORS issues when API is called from the frontend app.
# Handle Cross-Origin Resource Sharing (CORS) in order to accept cross-origin Ajax requests.

# Read more: https://github.com/cyu/rack-cors

# Rails.application.config.middleware.insert_before 0, Rack::Cors do
#   allow do
#     origins "example.com"
#
#     resource "*",
#       headers: :any,
#       methods: [:get, :post, :put, :patch, :delete, :options, :head]
#   end
# end

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    # Named rather than open: the session rides on a cookie now, and a browser
    # only sends one to a cross-origin caller we have said we trust.
    origins Rails.application.config_for(:app).web_url!

    resource '/api/*', **{
      headers:     :any,
      methods:     %i[get post put patch delete options head],
      credentials: true
    }
  end
end
