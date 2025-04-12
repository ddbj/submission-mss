require "rails_helper"

using TmpUploadedFile

RSpec.describe UploadJob do
  include ActiveJob::TestHelper

  before do
    submission = create(:submission, **{
      mass_id:        "NSUB000042",
      user:           build(:user, :alice),
      contact_person: build(:contact_person, :alice)
    })

    upload = create(:upload, **{
      submission:,
      created_at: "2022-01-02 12:34:56",

      via: build(:webui_upload, **{
        files: [
          Rack::Test::UploadedFile.tmp("example.ann")
        ]
      })
    })

    stub_request(:post, "https://www.googleapis.com/oauth2/v4/token").to_return(
      headers: {
        content_type: "application/json"
      },
      body: "{}"
    )

    stub_request(:get, "https://sheets.googleapis.com/v4/spreadsheets/WORKING_LIST_SHEET_ID/values:batchGet?ranges=WORKING_LIST_SHEET_NAME!A1:A100").to_return(
      headers: {
        content_type: "application/json"
      },

      body: JSON.generate(
        valueRanges: [
          values: 100.times.map { |i| [ "CELL-#{i}" ] }
        ]
      )
    )

    stub_request(:get, "https://sheets.googleapis.com/v4/spreadsheets/WORKING_LIST_SHEET_ID/values:batchGet?ranges=WORKING_LIST_SHEET_NAME!A101:A200").to_return(
      headers: {
        content_type: "application/json"
      },

      body: JSON.generate(
        valueRanges: [
          values: [
            [ "NSUB000042" ]
          ]
        ]
      )
    )

    stub_request(:put, "https://sheets.googleapis.com/v4/spreadsheets/WORKING_LIST_SHEET_ID/values/WORKING_LIST_SHEET_NAME!L101").with(query: hash_including)

    UploadJob.perform_now upload
  end

  example do
    dir = Rails.root.join("tmp/storage/submissions/NSUB000042/20220102-123456")

    expect(dir.ftype).to                     eq("directory")
    expect(dir.join("example.ann").ftype).to eq("file")

    expect(WebMock).to have_requested(:put, "https://sheets.googleapis.com/v4/spreadsheets/WORKING_LIST_SHEET_ID/values/WORKING_LIST_SHEET_NAME!L101").with(
      query: {
        valueInputOption: "RAW"
      },

      body: {
        values: [
          [ "20220102-123456" ]
        ]
      }
    )

    expect(MailDeliveryJob).to have_been_enqueued.with("SubmissionMailer", "submitter_confirmation", any_args)
    expect(MailDeliveryJob).to have_been_enqueued.with("SubmissionMailer", "curator_notification", any_args)
  end
end
