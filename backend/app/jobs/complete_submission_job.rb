class CompleteSubmissionJob < ApplicationJob
  queue_as :default

  def perform(submission)
    submission.uploads.first&.copy_flles_to_submissions_dir

    add_row_to_working_list submission

    CompleteSubmissionMailer.with(submission:).for_submitter.deliver_now
  end

  private

  def add_row_to_working_list(submission)
    sheet_id   = ENV.fetch('MSS_WORKING_LIST_SHEET_ID')
    sheet_name = ENV.fetch('MSS_WORKING_LIST_SHEET_NAME')

    authorizer = Google::Auth::ServiceAccountCredentials.from_env(scope: 'https://www.googleapis.com/auth/spreadsheets')
    service    = Google::Apis::SheetsV4::SheetsService.new

    service.authorization = authorizer

    row = Google::Apis::SheetsV4::ValueRange.new(values: [to_hash(submission).values])

    service.append_spreadsheet_value sheet_id, "#{sheet_name}!A1", row, **{
      insert_data_option: 'INSERT_ROWS',
      value_input_option: 'RAW'
    }
  end

  def to_hash(submission)
    {
      mass_id:                    submission.mass_id,
      curator:                    nil,
      created_date:               submission.created_at.to_date,
      status:                     nil,
      description:                submission.description,
      contact_person_email:       submission.contact_person.email,
      contact_person_full_name:   submission.contact_person.full_name,
      contact_person_affiliation: submission.contact_person.affiliation,
      other_person:               submission.other_people.order(:position).map(&:email_address_with_name).join('; '),
      dway_account:               submission.user.id_token.fetch('preferred_username'),
      date_arrival_date:          submission.uploads.map(&:dirname).join('; '),
      check_start_date:           nil,
      finish_date:                nil,
      sequencer:                  submission.sequencer_text,
      annotation_pipeline:        submission.dfast? ? 'DFAST' : nil,
      hup:                        submission.hold_date || 'non-HUP',
      tpa:                        submission.tpa?,
      data_type:                  submission.data_type.upcase,
      total_entry:                submission.entries_count,
      accession:                  nil,
      prefix_count:               nil,
      div:                        nil,
      bioproject:                 nil,
      biosample:                  nil,
      drr:                        nil,
      language:                   submission.email_language,
      mail_j:                     nil,
      mail_e:                     nil,
      memo:                       nil
    }
  end
end
