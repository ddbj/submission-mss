require 'test_helper'

class OpenapiTest < ActionDispatch::IntegrationTest
  test 'valid document' do
    assert_is_valid_document skooma_openapi_schema
  end
end
