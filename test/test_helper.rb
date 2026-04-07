ENV['RAILS_ENV'] ||= 'test'

require_relative '../config/environment'
require 'rails/test_help'

# skooma 0.3.7 requires minitest/unit, which was removed in minitest 6.
# Provide a shim until skooma is updated.
$LOAD_PATH.unshift Rails.root.join('test/support/shims').to_s

require 'minitest/mock'
require 'webmock/minitest'

WebMock.disable_net_connect! allow_localhost: true

Rails.root.glob('test/support/**/*.rb').sort_by(&:to_s).each {|f| require f }

class ActiveSupport::TestCase
  self.fixture_paths = [Rails.root.join('test/fixtures')]

  fixtures :all

  setup do
    Rails.root.glob('tmp/storage/*', &:rmtree)
  end
end

class ActionDispatch::IntegrationTest
  include Skooma::Minitest[Rails.root.join('schema/openapi.yml'), path_prefix: '/api']
end
