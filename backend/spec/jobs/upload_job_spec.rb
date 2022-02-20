require 'rails_helper'

using TmpUploadedFile

RSpec.describe UploadJob do
  include ActiveJob::TestHelper

  around do |example|
    Dir.mktmpdir do |dir|
      env = {
        MSS_WORKING_LIST_SHEET_ID:   'SHEET_ID',
        MSS_WORKING_LIST_SHEET_NAME: 'SHEET_NAME',
        SUBMISSIONS_DIR:             dir
      }

      ClimateControl.modify(env, &example)
    end
  end

  before do
    submission = create(:submission, **{
      id:   42,
      user: build(:user, :alice),
      contact_person: build(:contact_person, :alice)
    }).reload

    upload = create(:upload, **{
      submission:,
      created_at: '2022-01-02 12:34:56',

      files: [
        Rack::Test::UploadedFile.tmp('example.ann')
      ]
    })

    stub_request(:post, 'https://www.googleapis.com/oauth2/v4/token').to_return(
      headers: {
        content_type: 'application/json'
      },
      body: '{}'
    )

    stub_request(:get, 'https://sheets.googleapis.com/v4/spreadsheets/SHEET_ID/values:batchGet?ranges=SHEET_NAME!A1:A100').to_return(
      headers: {
        content_type: 'application/json'
      },

      body: JSON.generate(
        valueRanges: [
          values: 100.times.map {|i| ["CELL-#{i}"] }
        ]
      )
    )

    stub_request(:get, 'https://sheets.googleapis.com/v4/spreadsheets/SHEET_ID/values:batchGet?ranges=SHEET_NAME!A101:A200').to_return(
      headers: {
        content_type: 'application/json'
      },

      body: JSON.generate(
        valueRanges: [
          values: [
            ['NSUB000042']
          ]
        ]
      )
    )

    stub_request(:put, 'https://sheets.googleapis.com/v4/spreadsheets/SHEET_ID/values/SHEET_NAME!K101').with(query: hash_including)

    UploadJob.perform_now upload
  end

  example do
    dir = Pathname.new(ENV.fetch('SUBMISSIONS_DIR')).join('NSUB000042/20220102-123456')

    expect(dir.ftype).to                     eq('directory')
    expect(dir.join('example.ann').ftype).to eq('file')

    expect(WebMock).to have_requested(:put, 'https://sheets.googleapis.com/v4/spreadsheets/SHEET_ID/values/SHEET_NAME!K101').with(
      query: {
        valueInputOption: 'RAW'
      },

      body: {
        values: [
          ['20220102-123456']
        ]
      }
    )

    expect(ActionMailer::MailDeliveryJob).to have_been_enqueued.with('SubmissionMailer', 'submitter_confirmation', any_args)
    expect(ActionMailer::MailDeliveryJob).to have_been_enqueued.with('SubmissionMailer', 'curator_notification', any_args)
  end
end

