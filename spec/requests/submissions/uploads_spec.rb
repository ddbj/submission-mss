require 'rails_helper'

RSpec.describe '/api/submissions/:mass_id/uploads', type: :request do
  let(:user) { create(:user, :alice) }

  let(:default_headers) {
    {
      Authorization: "Bearer #{user.token}",
      Accept:        'application/json'
    }
  }

  example 'create' do
    extraction = user.dfast_extractions.create!(dfast_job_ids: ['job-1'])
    submission = create(:submission, mass_id: 'NSUB000042', user: user)

    post "/api/submissions/#{submission.mass_id}/uploads", params: {
      upload: {
        via:           'dfast',
        extraction_id: extraction.id
      }
    }, as: :json

    expect(response).to conform_schema(200)
  end
end
