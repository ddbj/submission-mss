require 'test_helper'

class SubmissionsTest < ActionDispatch::IntegrationTest
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
    extraction = @user.dfast_extractions.create!(dfast_job_ids: ['job-1'])

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
  end

  test 'show' do
    get "/api/submissions/#{submissions(:alice_submission).mass_id}"

    assert_conform_schema 200
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
