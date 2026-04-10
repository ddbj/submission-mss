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

    path  = Rails.application.config_for(:app).upload_events_log!
    event = JSON.parse(File.read(path).lines.last)

    assert_equal submission.mass_id,        event['mass_id']
    assert_equal @user.uid,                 event['dway_account']
    assert_match(/\A\d{8}-\d{6}\z/,         event['data_arrival_date'])
  end
end
