require 'rails_helper'

RSpec.describe '/api/mass_directory_extractions', type: :request do
  let(:user) { create(:user, :alice) }

  let(:default_headers) {
    {
      Authorization: "Bearer #{user.token}",
      Accept:        'application/json'
    }
  }

  example 'create' do
    post '/api/mass_directory_extractions', as: :json

    expect(response).to conform_schema(201)
  end

  example 'show' do
    extraction = create(:mass_directory_extraction, user: user)

    get "/api/mass_directory_extractions/#{extraction.id}"

    expect(response).to conform_schema(200)
  end
end
