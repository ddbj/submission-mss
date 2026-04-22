require 'test_helper'

class UpdateWorkingListJobTest < ActiveJob::TestCase
  setup do
    @submission = Submission.create!(
      mass_id:        'NSUB000042',
      user:           users(:alice),
      tpa:            false,
      entries_count:  1,
      sequencer:      'ngs',
      data_type:      'wgs',
      description:    'some description',
      email_language: 'en',

      contact_person: ContactPerson.new(
        email:       'alice+contact@example.com',
        full_name:   'Alice Liddell',
        affiliation: 'Wonderland Inc.'
      )
    )

    Upload.create!(
      submission: @submission,
      via:        WebuiUpload.new,
      created_at: '2022-01-02 12:34:56'
    )

    stub_request(:post, 'https://www.googleapis.com/oauth2/v4/token').to_return(
      headers: {content_type: 'application/json'},
      body:    '{}'
    )

    stub_request(:get, 'https://sheets.googleapis.com/v4/spreadsheets/WORKING_LIST_SHEET_ID/values/WORKING_LIST_SHEET_NAME!A:A').to_return(
      headers: {content_type: 'application/json'},

      body: JSON.generate(
        values: 100.times.map {|i| ["CELL-#{i}"] } + [['NSUB000042']]
      )
    )

    stub_request(:put, 'https://sheets.googleapis.com/v4/spreadsheets/WORKING_LIST_SHEET_ID/values/WORKING_LIST_SHEET_NAME!L101').with(query: hash_including({}))
  end

  test 'updates the data_arrival_date cell in the working list' do
    UpdateWorkingListJob.perform_now @submission

    assert_requested :put, 'https://sheets.googleapis.com/v4/spreadsheets/WORKING_LIST_SHEET_ID/values/WORKING_LIST_SHEET_NAME!L101',
      body:  {values: [['20220102-123456']]},
      query: {valueInputOption: 'RAW'}
  end
end
