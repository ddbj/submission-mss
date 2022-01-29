require 'rails_helper'

RSpec.describe ProcessSubmissionJob do
  include ActiveJob::TestHelper

  def uploaded_file(dir, filename, content: '')
    file = Pathname.new(dir).join(filename).open('wb').tap {|f|
      f.write content
      f.rewind
    }

    Rack::Test::UploadedFile.new(file)
  end

  fixtures :users

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
    submission = Submission.create!(
      id:             42,
      user:           users(:alice),
      tpa:            true,
      dfast:          true,
      entries_count:  101,
      hold_date:      '2022-02-01',
      sequencer:      'sanger',
      data_type:      'wgs',
      description:    'some description',
      email_language: 'ja',
      created_at:     '2022-01-01'
    ) {|submission|
      Dir.mktmpdir do |dir|
        submission.uploads.build(
          created_at: '2022-01-02 12:34:56',

          files: [
            uploaded_file(dir, 'example.ann'),
            uploaded_file(dir, 'example.fasta')
          ]
        )
      end

      submission.build_contact_person(
        email:       'alice@example.com',
        full_name:   'Alice Liddell',
        affiliation: 'Example Inc.'
      )

      submission.other_people.build(
        email:     'bob@example.com',
        full_name: 'Bob',
        position:  0
      )
    }

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
            'alice@example.com',
            'Alice Liddell',
            'Example Inc.',
            'Bob <bob@example.com>',
            'alice-liddell',
            '20220102-123456',
            nil,
            nil,
            'Sanger dideoxy sequencing',
            'DFAST',
            '2022-02-01',
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

    expect(ActionMailer::MailDeliveryJob).to have_been_enqueued.with('SubmissionMailer', 'confirmation', any_args)
  end
end
