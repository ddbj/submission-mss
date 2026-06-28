require 'test_helper'

class GgsExtractionsTest < ActionDispatch::IntegrationTest
  setup do
    default_headers['Authorization'] = "Bearer #{users(:alice).token}"
  end

  test 'create' do
    post '/api/ggs_extractions', params: {
      ids: ['01234567-89ab-cdef-0000-000000000001']
    }, as: :json

    assert_conform_schema 201
  end

  test 'show' do
    get "/api/ggs_extractions/#{ggs_extractions(:alice_ggs_extraction).id}"

    assert_conform_schema 200
  end
end
