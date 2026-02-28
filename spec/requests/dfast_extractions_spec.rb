require 'rails_helper'

RSpec.describe '/api/dfast_extractions', type: :request do
  let(:user) { create(:user, :alice) }

  let(:default_headers) {
    {
      Authorization: "Bearer #{user.token}",
      Accept:        'application/json'
    }
  }

  example 'create' do
    post '/api/dfast_extractions', params: {
      ids: ['01234567-89ab-cdef-0000-000000000001']
    }, as: :json

    expect(response).to conform_schema(201)
  end

  example 'show' do
    extraction = user.dfast_extractions.create!(dfast_job_ids: ['job-1'])

    get "/api/dfast_extractions/#{extraction.id}"

    expect(response).to conform_schema(200)
  end
end
