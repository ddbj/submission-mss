class CompleteSubmissionJob < ApplicationJob
  queue_as :default

  def perform(submission)
    write_submission_files submission
    add_row_to_working_list submission

    CompleteSubmissionMailer.with(submission: submission).for_submitter.deliver_now

    submission.files.purge
  end

  private

  def write_submission_files(submission)
    return if submission.files.empty?

    output_dir = Pathname.new(ENV.fetch('SUBMISSIONS_DIR'))
    timestamp  = submission.created_at.strftime('%Y%m%d')
    work       = output_dir.join('.work', submission.mass_id, timestamp)
    dest       = output_dir.join(submission.mass_id)

    work.mkpath

    submission.files.each do |attachment|
      work.join(attachment.filename.to_s).open 'wb' do |f|
        attachment.download do |chunk|
          f.write chunk
        end
      end
    end

    FileUtils.move work, dest.tap(&:mkpath)
  end

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
      contact_person_email:       submission.contact_person.fetch('email'),
      contact_person_full_name:   submission.contact_person.fetch('full_name'),
      contact_person_affiliation: submission.contact_person.fetch('affiliation'),
      other_person:               submission.other_people.map { format_address(_1) }.join('; '),
      dway_account:               submission.user.id_token.fetch('preferred_username'),
      date_arrival_date:          submission.files.empty? ? nil : submission.created_at.to_date,
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

  def format_address(person)
    email, full_name = person.fetch_values('email', 'full_name')

    ApplicationMailer.email_address_with_name(email, full_name)
  end
end
