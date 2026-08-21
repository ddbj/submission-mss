require 'test_helper'

class SubmissionsTest < ActionDispatch::IntegrationTest
  include ActionMailer::TestHelper

  setup do
    @user = users(:alice)

    default_headers['Authorization'] = "Bearer #{@user.token}"
  end

  test 'index' do
    WorkingList.instance.stub :collect_statuses_and_accessions, {} do
      get '/api/submissions'
    end

    assert_conform_schema 200
  end

  test 'create' do
    extraction = @user.dfast_extractions.create!(dfast_job_ids: ['job-1'], state: 'fulfilled')

    post '/api/submissions', params: {
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
    }, as: :json

    assert_conform_schema 200

    submission = @user.submissions.order(:id).last

    path  = Rails.application.config_for(:app).upload_events_log!
    event = JSON.parse(File.read(path).lines.last)

    assert_equal submission.mass_id, event['mass_id']
    assert_equal @user.uid,          event['dway_account']
    assert_match(/\A\d{8}-\d{6}\z/,  event['data_arrival_date'])

    assert_enqueued_with job: CopySubmissionFilesJob
    assert_enqueued_with job: AddToWorkingListJob, args: [submission]

    assert_enqueued_email_with SubmissionMailer, :submitter_confirmation, params: {submission:}
    assert_enqueued_email_with SubmissionMailer, :curator_notification,   params: {submission:}
  end

  test 'create with an extraction belonging to someone else' do
    bob        = User.create!(uid: 'bob', email: 'bob@example.com')
    extraction = bob.dfast_extractions.create!(dfast_job_ids: ['job-1'], state: 'fulfilled')

    post '/api/submissions', params: {
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
    }, as: :json

    # Bob's files would otherwise be copied into a submission of Alice's.
    assert_conform_schema 404

    assert_empty @user.submissions.where.not(id: submissions(:alice_submission))
  end

  test 'show' do
    get "/api/submissions/#{submissions(:alice_submission).mass_id}"

    assert_conform_schema 200
  end

  test 'show (files not copied yet)' do
    submission = submissions(:alice_submission)
    upload     = submission.uploads.create!(via: WebuiUpload.new(files: [fixture_file_upload('test.fasta', 'text/plain')]))

    get "/api/submissions/#{submission.mass_id}"

    assert_conform_schema 200

    # The copy job has not run, so nothing is on disk: the upload answers for
    # the files it was given.
    assert_empty Dir.glob('*', base: upload.files_dir)

    files = response.parsed_body['submission']['uploads'].find { _1['id'] == upload.id }['files']

    assert_equal ['test.fasta'], files
  end

  test 'show (files copied)' do
    submission = submissions(:alice_submission)
    upload     = submission.uploads.create!(via: WebuiUpload.new(files: [fixture_file_upload('test.fasta', 'text/plain')]))

    upload.via.copy_files_to_submissions_dir

    get "/api/submissions/#{submission.mass_id}"

    assert_conform_schema 200

    files = response.parsed_body['submission']['uploads'].find { _1['id'] == upload.id }['files']

    assert_equal ['test.fasta'], files
  end

  test 'show (imported files not copied yet)' do
    submission = submissions(:alice_submission)
    extraction = dfast_extractions(:alice_dfast_extraction)

    extraction.working_dir.mkpath

    %w[test.ann test.fasta].each do |name|
      extraction.files.create!(name:, dfast_job_id: 'job-1', parsing: false)

      FileUtils.touch extraction.working_dir.join(name)
    end

    upload = submission.uploads.create!(via: DfastUpload.new(extraction:))

    get "/api/submissions/#{submission.mass_id}"

    assert_conform_schema 200

    files = response.parsed_body['submission']['uploads'].find { _1['id'] == upload.id }['files']

    assert_equal %w[test.ann test.fasta], files

    # And the same once they have been copied, which happens in one move so
    # that the list never shrinks in between.
    upload.via.copy_files_to_submissions_dir

    get "/api/submissions/#{submission.mass_id}"

    files = response.parsed_body['submission']['uploads'].find { _1['id'] == upload.id }['files']

    assert_equal %w[test.ann test.fasta], files
  end

  test 'show (not found)' do
    get '/api/submissions/NSUB999999'

    assert_conform_schema 404
  end

  test 'show (upload disabled)' do
    submission = submissions(:alice_submission)

    FileUtils.touch submission.root_dir.tap(&:mkpath).join('disable-upload')

    get "/api/submissions/#{submission.mass_id}"

    assert_conform_schema 403
  end

  test 'last_submitted' do
    get '/api/submissions/last_submitted'

    assert_conform_schema 200
  end
end
