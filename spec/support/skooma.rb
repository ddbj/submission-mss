spec = Rails.root.join('schema/openapi.yml')

RSpec.configure do |config|
  config.include Skooma::RSpec[spec, path_prefix: '/api'], type: :request
end
