class ProcessSubmissionJob < ApplicationJob
  queue_as :default

  def perform(submission)
    submission.uploads.first&.copy_flles_to_submissions_dir

    add_row_to_working_list submission

    SubmissionMailer.with(submission:).submitter_confirmation.deliver_later
    SubmissionMailer.with(submission:).curator_notification.deliver_later
  end

  private

  def add_row_to_working_list(submission)
    sheet_id   = ENV.fetch('MSS_WORKING_LIST_SHEET_ID')
    sheet_name = ENV.fetch('MSS_WORKING_LIST_SHEET_NAME')

    authorizer = Google::Auth::ServiceAccountCredentials.from_env(scope: 'https://www.googleapis.com/auth/spreadsheets')
    service    = Google::Apis::SheetsV4::SheetsService.new

    service.authorization = authorizer

    row = Google::Apis::SheetsV4::ValueRange.new(values: [submission.to_working_sheet_row.values])

    service.append_spreadsheet_value sheet_id, "#{sheet_name}!A1", row, **{
      insert_data_option: 'INSERT_ROWS',
      value_input_option: 'RAW'
    }
  end
end
