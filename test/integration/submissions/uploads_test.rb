require 'test_helper'

class Submissions::UploadsTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:alice)

    default_headers['Authorization'] = "Bearer #{@user.token}"
  end

  test 'create' do
    extraction = @user.dfast_extractions.create!(dfast_job_ids: ['job-1'])
    submission = submissions(:alice_submission)

    post "/api/submissions/#{submission.mass_id}/uploads", params: {
      upload: {
        via:           'dfast',
        extraction_id: extraction.id
      }
    }, as: :json

    assert_conform_schema 204
  end
end
