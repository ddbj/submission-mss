require 'test_helper'

class DfastExtractionsTest < ActionDispatch::IntegrationTest
  setup do
    default_headers['Authorization'] = "Bearer #{users(:alice).token}"
  end

  test 'create' do
    post '/api/dfast_extractions', params: {
      ids: ['01234567-89ab-cdef-0000-000000000001']
    }, as: :json

    assert_conform_schema 201
  end

  test 'show' do
    get "/api/dfast_extractions/#{dfast_extractions(:alice_dfast_extraction).id}"

    assert_conform_schema 200
  end
end
