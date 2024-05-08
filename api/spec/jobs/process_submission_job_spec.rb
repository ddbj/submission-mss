require 'rails_helper'

using TmpUploadedFile

RSpec.describe ProcessSubmissionJob do
  include ActiveJob::TestHelper

  before do
    submission = create(:submission, **{
      mass_id:        'NSUB000042',
      user:           build(:user, :alice),
      tpa:            true,
      entries_count:  101,
      hold_date:      '2022-01-03',
      contact_person: build(:contact_person, :alice),
      sequencer:      'sanger',
      data_type:      'wgs',
      description:    'some description',
      email_language: 'ja',
      created_at:     '2022-01-01',

      other_people: [
        build(:other_person, :bob),
        build(:other_person, :carol)
      ]
    })

    upload = create(:upload, **{
      submission:,
      created_at: '2022-01-02 12:34:56',

      via: build(:webui_upload, **{
        files: [
          Rack::Test::UploadedFile.tmp('example.ann'),
          Rack::Test::UploadedFile.tmp('example.fasta')
        ]
      })
    })

    stub_request(:post, 'https://www.googleapis.com/oauth2/v4/token').to_return(
      headers: {
        content_type: 'application/json'
      },
      body: '{}'
    )

    stub_request(:post, 'https://sheets.googleapis.com/v4/spreadsheets/SHEET_ID/values/SHEET_NAME!A1:append').with(query: hash_including)

    ProcessSubmissionJob.perform_now upload
  end

  example do
    dir = Pathname.new(ENV.fetch('SUBMISSIONS_DIR')).join('NSUB000042/20220102-123456')

    expect(dir.ftype).to                       eq('directory')
    expect(dir.join('example.ann').ftype).to   eq('file')
    expect(dir.join('example.fasta').ftype).to eq('file')

    expect(WebMock).to have_requested(:post, 'https://sheets.googleapis.com/v4/spreadsheets/SHEET_ID/values/SHEET_NAME!A1:append').with(
      query: {
        insertDataOption: 'INSERT_ROWS',
        valueInputOption: 'RAW'
      },

      body: {
        values: [
          [
            'NSUB000042',
            nil,
            '2022-01-01',
            nil,
            'some description',
            'alice+contact@foo.example.com',
            'Alice Liddell',
            'Wonderland Inc.',
            'Bob <bob@bar.example.com>; Carol <carol@baz.example.com>',
            'alice-liddell',
            'alice+idp@example.com',
            '20220102-123456',
            nil,
            nil,
            'Sanger dideoxy sequencing',
            'webui',
            '2022-01-03',
            true,
            'WGS',
            101,
            nil,
            nil,
            nil,
            nil,
            nil,
            nil,
            'ja',
            nil,
            nil,
            nil
          ]
        ]
      }
    )

    expect(ActionMailer::MailDeliveryJob).to have_been_enqueued.with('SubmissionMailer', 'submitter_confirmation', any_args)
    expect(ActionMailer::MailDeliveryJob).to have_been_enqueued.with('SubmissionMailer', 'curator_notification', any_args)
  end
end
