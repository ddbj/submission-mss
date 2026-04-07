require 'test_helper'

class MassDirectoryExtractionsTest < ActionDispatch::IntegrationTest
  setup do
    default_headers['Authorization'] = "Bearer #{users(:alice).token}"
  end

  test 'create' do
    post '/api/mass_directory_extractions', as: :json

    assert_conform_schema 201
  end

  test 'show' do
    get "/api/mass_directory_extractions/#{mass_directory_extractions(:alice_mass_directory_extraction).id}"

    assert_conform_schema 200
  end
end
