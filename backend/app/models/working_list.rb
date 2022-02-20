class WorkingList
  def self.instance
    new(
      sheet_id:   ENV.fetch('MSS_WORKING_LIST_SHEET_ID'),
      sheet_name: ENV.fetch('MSS_WORKING_LIST_SHEET_NAME')
    )
  end

  def initialize(sheet_id:, sheet_name:)
    @sheet_id   = sheet_id
    @sheet_name = sheet_name

    @service               = Google::Apis::SheetsV4::SheetsService.new
    @service.authorization = Google::Auth::ServiceAccountCredentials.from_env(scope: 'https://www.googleapis.com/auth/spreadsheets')
  end

  def add_new_submission(submission)
    range = Google::Apis::SheetsV4::ValueRange.new(values: [
      submission.to_working_sheet_row.values
    ])

    @service.append_spreadsheet_value @sheet_id, "#{@sheet_name}!A1", range, **{
      insert_data_option: 'INSERT_ROWS',
      value_input_option: 'RAW'
    }
  end

  def update_data_arrival_date(submission)
    row = find_row_number_by_mass_id(submission.mass_id)

    raise submission.mass_id unless row

    range = Google::Apis::SheetsV4::ValueRange.new(values: [
      [submission.to_working_sheet_row.fetch(:data_arrival_date)]
    ])

    @service.update_spreadsheet_value @sheet_id, "#{@sheet_name}!K#{row}", range, **{
      value_input_option: 'RAW'
    }
  end

  def find_row_number_by_mass_id(target_mass_id, offset: 1, limit: 100)
    res    = @service.batch_get_spreadsheet_values(@sheet_id, ranges: "#{@sheet_name}!A#{offset}:A#{offset + limit - 1}")
    values = res.value_ranges.first.values

    values.each_with_index do |(mass_id), i|
      return offset + i if mass_id == target_mass_id
    end

    return nil if values.size < limit

    find_row_number_by_mass_id(target_mass_id, offset: offset + limit, limit:)
  end
end
