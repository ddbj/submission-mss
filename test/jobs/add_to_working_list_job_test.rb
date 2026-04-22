require 'test_helper'

using TmpUploadedFile

class AddToWorkingListJobTest < ActiveJob::TestCase
  setup do
    stub_request(:post, 'https://www.googleapis.com/oauth2/v4/token').to_return_json(body: {})

    stub_request(:post, 'https://sheets.googleapis.com/v4/spreadsheets/WORKING_LIST_SHEET_ID/values/WORKING_LIST_SHEET_NAME!A1:append').with(query: hash_including({}))
  end

  test 'appends a new row to the working list' do
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

    Upload.create!(
      submission:,
      via:        WebuiUpload.new,
      created_at: '2022-01-02 12:34:56'
    )

    AddToWorkingListJob.perform_now submission

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
  end
end
