require 'rails_helper'

using Module.new {
  refine Rack::Test::UploadedFile.singleton_class do
    def tmp(filename, content: '')
      Dir.mktmpdir {|dir|
        file = Pathname.new(dir).join(filename).open('wb').tap {|f|
          f.write content
          f.rewind
        }

        new(file)
      }
    end
  end
}

RSpec.describe ProcessSubmissionJob do
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
      id:             42,
      user:           build(:user, :alice),
      tpa:            true,
      dfast:          true,
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
      ],

      uploads: [
        build(:upload, **{
          created_at: '2022-01-02 12:34:56',

          files: [
            Rack::Test::UploadedFile.tmp('example.ann'),
            Rack::Test::UploadedFile.tmp('example.fasta')
          ]
        })
      ]
    })

    stub_request(:post, 'https://www.googleapis.com/oauth2/v4/token').to_return(
      headers: {
        content_type: 'application/json'
      },
      body: '{}'
    )

    stub_request(:post, 'https://sheets.googleapis.com/v4/spreadsheets/SHEET_ID/values/SHEET_NAME!A1:append').with(query: hash_including)

    ProcessSubmissionJob.perform_now submission
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
            'alice+contact@example.com',
            'Alice Liddell',
            'Wonderland Inc.',
            'Bob <bob@example.com>; Carol <carol@example.com>',
            'alice-liddell',
            '20220102-123456',
            nil,
            nil,
            'Sanger dideoxy sequencing',
            'DFAST',
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
