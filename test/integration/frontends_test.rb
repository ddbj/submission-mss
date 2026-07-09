require 'test_helper'

class FrontendsTest < ActionDispatch::IntegrationTest
  test 'root serves the SPA shell with the runtime config injected' do
    get '/'

    assert_response :success
    assert_select 'meta[name=?]', 'sentry-dsn'
    assert_select 'meta[name=?][content=?]', 'sentry-environment', 'test'
  end

  test 'client-side routes serve the SPA shell too' do
    get '/home/submission/new'

    assert_response :success
    assert_select 'meta[name=?][content=?]', 'sentry-environment', 'test'
  end

  test 'injects the configured Sentry DSN into the shell' do
    config = ActiveSupport::OrderedOptions.new
    config.sentry_dsn = 'https://public@sentry.example.com/1'

    Rails.application.stub :config_for, ->(*) { config } do
      get '/'
    end

    assert_select 'meta[name=?][content=?]', 'sentry-dsn', 'https://public@sentry.example.com/1'
  end
end
