require 'test_helper'

class Submissions::UploadsTest < ActionDispatch::IntegrationTest
  include ActionMailer::TestHelper

  setup do
    @user = users(:alice)

    default_headers['Authorization'] = "Bearer #{@user.token}"
  end

  test 'create' do
    extraction = @user.dfast_extractions.create!(dfast_job_ids: ['job-1'], state: 'fulfilled')
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

    assert_equal submission.mass_id, event['mass_id']
    assert_equal @user.uid,          event['dway_account']
    assert_match /\A\d{8}-\d{6}\z/,  event['data_arrival_date']

    assert_enqueued_with job: CopySubmissionFilesJob
    assert_enqueued_with job: UpdateWorkingListJob, args: [submission]

    assert_enqueued_email_with SubmissionMailer, :submitter_confirmation, params: {submission:}
    assert_enqueued_email_with SubmissionMailer, :curator_notification,   params: {submission:}
  end

  test 'create with an extraction belonging to someone else' do
    bob        = User.create!(uid: 'bob', email: 'bob@example.com')
    extraction = bob.dfast_extractions.create!(dfast_job_ids: ['job-1'], state: 'fulfilled')

    post_upload extraction

    # Bob's files would otherwise be copied into Alice's submission.
    assert_conform_schema 404

    assert_no_enqueued_jobs
  end

  test 'create with an extraction that has nothing to give' do
    extraction = @user.dfast_extractions.create!(dfast_job_ids: ['job-1'], state: 'rejected')

    post_upload extraction

    assert_conform_schema 404

    assert_no_enqueued_jobs
  end

  test 'create with a payload we cannot make an upload out of' do
    post "/api/submissions/#{submissions(:alice_submission).mass_id}/uploads", params: {
      upload: {
        via: 'dfast'
      }
    }, as: :json

    assert_conform_schema 422

    assert_no_enqueued_jobs
  end

  private

  def post_upload(extraction)
    post "/api/submissions/#{submissions(:alice_submission).mass_id}/uploads", params: {
      upload: {
        via:           'dfast',
        extraction_id: extraction.id
      }
    }, as: :json
  end
end
