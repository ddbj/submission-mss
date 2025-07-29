class WorkingList
  def self.instance
    @instance ||= begin
      config = Rails.application.config_for(:working_list)

      new(
        sheet_id:   config.sheet_id!,
        sheet_name: config.sheet_name!
      )
    end
  end

  def initialize(sheet_id:, sheet_name:)
    @sheet_id   = sheet_id
    @sheet_name = sheet_name

    @service = Google::Apis::SheetsV4::SheetsService.new

    unless Rails.env.test?
      config = Rails.application.config_for(:google)

      @service.authorization = Google::Auth::ServiceAccountCredentials.make_creds(
        scope: 'https://www.googleapis.com/auth/spreadsheets',

        json_key_io: StringIO.new({
          account_type: 'service_account',
          client_email: config.client_email!,
          client_id:    config.client_id!,
          private_key:  config.private_key!
        }.to_json)
      )
    end
  end

  def add_new_submission(submission)
    range = Google::Apis::SheetsV4::ValueRange.new(values: [
      to_row(submission).values
    ])

    Retriable.with_context :google do
      @service.append_spreadsheet_value @sheet_id, "#{@sheet_name}!A1", range, **{
        insert_data_option: 'INSERT_ROWS',
        value_input_option: 'RAW'
      }
    end
  end

  def update_data_arrival_date(submission)
    row = find_row_number_by_mass_id(submission.mass_id)

    raise submission.mass_id unless row

    range = Google::Apis::SheetsV4::ValueRange.new(values: [
      [to_row(submission).fetch(:data_arrival_date)]
    ])

    Retriable.with_context :google do
      @service.update_spreadsheet_value @sheet_id, "#{@sheet_name}!L#{row}", range, **{
        value_input_option: 'RAW'
      }
    end
  end

  def to_row(submission)
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
      dway_account:               submission.user.uid,
      dway_account_email:         submission.user.email,
      data_arrival_date:          submission.uploads.map(&:timestamp).join('; '),
      check_start_date:           nil,
      finish_date:                nil,
      sequencer:                  submission.sequencer_text,
      upload_via:                 submission.uploads.first.via_ident,
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

  WorkingListState = Data.define(:status, :accessions)

  def collect_statuses_and_accessions(target_mass_ids)
    mass_ids, statuses, accessions = [
      "#{@sheet_name}!A2:A",
      "#{@sheet_name}!D2:D",
      "#{@sheet_name}!U2:U"
    ].map {|range|
      Retriable.with_context(:google) {
        @service.get_spreadsheet_values(@sheet_id, range).values&.map(&:first) || []
      }
    }

    mass_ids.zip(statuses, accessions).filter_map {|mass_id, status, accession|
      next false unless target_mass_ids.include?(mass_id)

      state = WorkingListState.new(status:, accessions: accession&.split(',') || [])

      [mass_id, state]
    }.to_h
  end

  private

  def find_row_number_by_mass_id(target_mass_id, offset: 1, limit: 100)
    res = Retriable.with_context(:google) {
      @service.batch_get_spreadsheet_values(@sheet_id, ranges: "#{@sheet_name}!A#{offset}:A#{offset + limit - 1}")
    }

    values = res.value_ranges.first.values

    values.each_with_index do |(mass_id), i|
      return offset + i if mass_id == target_mass_id
    end

    return nil if values.size < limit

    find_row_number_by_mass_id(target_mass_id, offset: offset + limit, limit:)
  end
end
