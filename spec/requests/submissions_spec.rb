require 'rails_helper'

RSpec.describe '/api/submissions', type: :request do
  let(:user) { create(:user, :alice) }

  let(:default_headers) {
    {
      Authorization: "Bearer #{user.token}",
      Accept:        'application/json'
    }
  }

  example 'index' do
    create :submission, mass_id: 'NSUB000042', user: user

    allow(WorkingList.instance).to receive(:collect_statuses_and_accessions).and_return({})

    get '/api/submissions'

    expect(response).to conform_schema(200)
  end

  example 'create' do
    extraction = user.dfast_extractions.create!(dfast_job_ids: ['job-1'])

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

    expect(response).to conform_schema(200)
  end

  example 'show' do
    create :submission, mass_id: 'NSUB000042', user: user

    get '/api/submissions/NSUB000042'

    expect(response).to conform_schema(200)
  end

  example 'show (not found)' do
    get '/api/submissions/NSUB000042'

    expect(response).to conform_schema(404)
  end

  example 'show (upload disabled)' do
    submission = create(:submission, mass_id: 'NSUB000042', user: user)
    File.write submission.root_dir.tap(&:mkpath).join('disable-upload'), ''

    get '/api/submissions/NSUB000042'

    expect(response).to conform_schema(403)
  end

  example 'last_submitted' do
    submission = create(:submission, user: user)

    create :contact_person, :alice, submission: submission
    create :other_person, :bob, submission: submission

    get '/api/submissions/last_submitted'

    expect(response).to conform_schema(200)
  end
end
