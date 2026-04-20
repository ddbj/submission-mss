ENV['RAILS_ENV'] ||= 'test'

require_relative '../config/environment'
require 'rails/test_help'

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
