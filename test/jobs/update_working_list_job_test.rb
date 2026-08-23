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

    ['2022-01-02 12:34:56', '2022-01-05 09:00:00'].each do |created_at|
      Upload.create!(submission: @submission, via: WebuiUpload.new, created_at:)
    end

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

  # A submission is handed files more than once, and the cell holds every
  # directory it has been handed them in.
  test 'updates the data_arrival_date cell in the working list' do
    UpdateWorkingListJob.perform_now @submission

    assert_requested :put, 'https://sheets.googleapis.com/v4/spreadsheets/WORKING_LIST_SHEET_ID/values/WORKING_LIST_SHEET_NAME!L101',
      body:  {values: [['20220102-123456; 20220105-090000']]},
      query: {valueInputOption: 'RAW'}
  end

  test 'a submission the working list has never heard of' do
    stub_request(:get, 'https://sheets.googleapis.com/v4/spreadsheets/WORKING_LIST_SHEET_ID/values/WORKING_LIST_SHEET_NAME!A:A').to_return(
      headers: {content_type: 'application/json'},
      body:    JSON.generate(values: [['NSUB000001']])
    )

    # It is listed when it is first sent, so a row that is not there when
    # another upload arrives means that listing did not happen. Said the same
    # way whichever submission it is: a sentence that named it would be one
    # thing to answer for per submission, none of them saying what went wrong.
    error = assert_raises WorkingList::MissingRow do
      UpdateWorkingListJob.perform_now @submission
    end

    assert_equal 'the working list has no row for this submission', error.message
  end
end
