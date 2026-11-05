require 'test_helper'

# A submission the GGS submission portal makes with the submitter's token is the
# portal's to look after: it writes to the submitter and the curators itself,
# and further files come through it, so that it knows of every version. We
# number it, list it in the working list and put its files in place, as for any
# other.
class PortalManagedSubmissionsTest < ActionDispatch::IntegrationTest
  include ActionMailer::TestHelper

  setup do
    stub_jwks!

    @user = users(:alice)
  end

  def bearer(user)
    {Authorization: "Bearer #{bearer_token_for(user)}"}
  end

  def fulfilled_extraction
    @user.dfast_extractions.create!(dfast_job_ids: ['job-1'], state: 'fulfilled').tap {
      it.files.create!(name: 'test.ann', dfast_job_id: 'job-1', parsing: false)
    }
  end

  def submission_params(extraction)
    {
      submission: {
        tpa:            false,
        upload_via:     'dfast',
        extraction_id:  extraction.id,
        entries_count:  1,
        hold_date:      nil,
        sequencer:      'ngs',
        data_type:      'wgs',
        description:    'test',
        email_language: 'en',

        contact_person: {
          email:       'alice@example.com',
          full_name:   'Alice Liddell',
          affiliation: 'Wonderland Inc.'
        },

        other_people: []
      }
    }
  end

  def upload_params(extraction)
    {
      upload: {
        via:           'dfast',
        extraction_id: extraction.id
      }
    }
  end

  def portal_submission
    submissions(:alice_submission).tap { it.update!(portal_managed: true) }
  end

  test 'made with a token: numbered, listed and put in place, but no mail from us' do
    post '/api/submissions', params: submission_params(fulfilled_extraction), as: :json, headers: bearer(@user)

    assert_conform_schema 200

    submission = @user.submissions.order(:id).last

    assert submission.portal_managed?

    assert_enqueued_with job: CopySubmissionFilesJob
    assert_enqueued_with job: AddToWorkingListJob, args: [submission]

    assert_no_enqueued_emails
  end

  test 'made through our pages: ours, mails and all' do
    sign_in @user

    post '/api/submissions', params: submission_params(fulfilled_extraction), as: :json

    assert_conform_schema 200

    submission = @user.submissions.order(:id).last

    assert_not submission.portal_managed?

    assert_enqueued_email_with SubmissionMailer, :submitter_confirmation, params: {submission:}
    assert_enqueued_email_with SubmissionMailer, :curator_notification,   params: {submission:}
  end

  test 'more files from the portal: put in place, but no mail from us' do
    submission = portal_submission

    post "/api/submissions/#{submission.mass_id}/uploads", params: upload_params(fulfilled_extraction), as: :json, headers: bearer(@user)

    assert_conform_schema 204

    assert_enqueued_with job: CopySubmissionFilesJob
    assert_enqueued_with job: UpdateWorkingListJob, args: [submission]

    assert_no_enqueued_emails
  end

  test 'more files through our pages are turned away' do
    sign_in @user

    submission = portal_submission

    extraction = fulfilled_extraction

    assert_no_difference -> { submission.uploads.count } do
      post "/api/submissions/#{submission.mass_id}/uploads", params: upload_params(extraction), as: :json
    end

    # The portal would never hear of them, and its versions would no longer be
    # what the curators have.
    assert_conform_schema 403

    assert_no_enqueued_jobs
  end

  test 'a token on a submission made through our pages: ours, mails and all' do
    submission = submissions(:alice_submission)

    post "/api/submissions/#{submission.mass_id}/uploads", params: upload_params(fulfilled_extraction), as: :json, headers: bearer(@user)

    assert_conform_schema 204

    assert_enqueued_email_with SubmissionMailer, :submitter_confirmation, params: {submission:}
    assert_enqueued_email_with SubmissionMailer, :curator_notification,   params: {submission:}
  end

  test 'show says where the portal keeps it' do
    sign_in @user

    submission = portal_submission

    with_app_config portal_submission_url_template: 'https://portal.example.org/submissions/{mass_id}' do
      get "/api/submissions/#{submission.mass_id}"
    end

    assert_conform_schema 200

    assert_equal true,                                               response.parsed_body.dig('submission', 'portal_managed')
    assert_equal 'https://portal.example.org/submissions/NSUB000001', response.parsed_body.dig('submission', 'portal_url')
  end

  test 'index says which ones the portal keeps' do
    sign_in @user

    portal_submission

    @user.submissions.create!(mass_id: 'NSUB000002', tpa: false, entries_count: 1, sequencer: 'ngs', data_type: 'wgs', description: 'ours', email_language: 'en')

    WorkingList.instance.stub :collect_statuses_and_accessions, {} do
      get '/api/submissions'
    end

    assert_conform_schema 200

    managed = response.parsed_body['submissions'].to_h { [it['id'], [it['portal_managed'], it['portal_url']]] }

    # No template in the test environment: the portal is named, but not linked.
    assert_equal({'NSUB000001' => [true, nil], 'NSUB000002' => [false, nil]}, managed)
  end
end
