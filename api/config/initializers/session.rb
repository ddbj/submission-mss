Rails.application.configure do
  config.middleware.use ActionDispatch::Cookies
  config.middleware.use ActionDispatch::Session::CookieStore, key: "_mssform"
end
