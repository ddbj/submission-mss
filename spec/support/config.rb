RSpec.configure do |config|
  config.include RSpec::DefaultHttpHeader, type: :request
end
