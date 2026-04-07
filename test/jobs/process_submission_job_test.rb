require 'test_helper'

using TmpUploadedFile

class ProcessSubmissionJobTest < ActiveJob::TestCase
  include ActionMailer::TestHelper

  setup do
    stub_request(:post, 'https://www.googleapis.com/oauth2/v4/token').to_return_json(body: {})

    stub_request(:post, 'https://sheets.googleapis.com/v4/spreadsheets/WORKING_LIST_SHEET_ID/values/WORKING_LIST_SHEET_NAME!A1:append').with(query: hash_including({}))
  end

  test 'process submission' do
    submission = Submission.create!(
      mass_id:        'NSUB000042',
      user:           users(:alice),
      tpa:            true,
      entries_count:  101,
      hold_date:      '2022-01-03',
      sequencer:      'sanger',
      data_type:      'wgs',
      description:    'some description',
      email_language: 'ja',
      created_at:     '2022-01-01',

      contact_person: ContactPerson.new(
        email:       'alice+contact@example.com',
        full_name:   'Alice Liddell',
        affiliation: 'Wonderland Inc.'
      ),

      other_people: [
        OtherPerson.new(position: 0, email: 'bob@bar.example.com', full_name: 'Bob'),
        OtherPerson.new(position: 1, email: 'carol@baz.example.com', full_name: 'Carol')
      ]
    )

    via = WebuiUpload.create!(files: [
      Rack::Test::UploadedFile.tmp('example.ann'),
      Rack::Test::UploadedFile.tmp('example.fasta')
    ])

    upload = Upload.create!(
      submission:,
      via:,
      created_at: '2022-01-02 12:34:56'
    )

    ProcessSubmissionJob.perform_now upload

    dir = Rails.root.join('tmp/storage/submissions/NSUB000042/20220102-123456')

    assert_equal 'directory', dir.ftype
    assert_equal 'file',      dir.join('example.ann').ftype
    assert_equal 'file',      dir.join('example.fasta').ftype

    assert_requested :post, 'https://sheets.googleapis.com/v4/spreadsheets/WORKING_LIST_SHEET_ID/values/WORKING_LIST_SHEET_NAME!A1:append',
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
            'Bob <bob@bar.example.com>; Carol <carol@baz.example.com>',
            'alice',
            'alice@example.com',
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

    assert_enqueued_email_with SubmissionMailer, :submitter_confirmation, params: {submission:}
    assert_enqueued_email_with SubmissionMailer, :curator_notification, params: {submission:}
  end

  test 'trim whitespace from contact fields in annotation files' do
    ann_content = <<~TSV
      COMMON\tSUBMITTER\t\tcontact\t Alice Liddell
      \t\t\temail\t alice@example.com
      \t\t\tinstitute\t Wonderland Inc.
      ENTRY\ttest
    TSV

    submission = Submission.create!(
      mass_id:        'NSUB000099',
      user:           users(:alice),
      tpa:            false,
      entries_count:  1,
      sequencer:      'ngs',
      data_type:      'wgs',
      email_language: 'en',
      created_at:     '2022-01-01',

      contact_person: ContactPerson.new(
        email:       'alice+contact@example.com',
        full_name:   'Alice Liddell',
        affiliation: 'Wonderland Inc.'
      )
    )

    via = WebuiUpload.create!(files: [
      Rack::Test::UploadedFile.tmp('example.ann', content: ann_content),
      Rack::Test::UploadedFile.tmp('example.fasta')
    ])

    upload = Upload.create!(
      submission:,
      via:,
      created_at: '2022-01-02 12:34:56'
    )

    ProcessSubmissionJob.perform_now upload

    result = Rails.root.join('tmp/storage/submissions/NSUB000099/20220102-123456/example.ann').read

    assert_equal <<~TSV, result
      COMMON\tSUBMITTER\t\tcontact\tAlice Liddell
      \t\t\temail\talice@example.com
      \t\t\tinstitute\tWonderland Inc.
      ENTRY\ttest
    TSV
  end
end
