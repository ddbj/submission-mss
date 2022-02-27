RSpec.configure do |config|
  config.around do |example|
    env = {
      MAIL_ALLOWED_DOMAINS:        nil,
      MSSFORM_URL:                 'http://mssform.example.com',
      MSS_WORKING_LIST_SHEET_ID:   'SHEET_ID',
      MSS_WORKING_LIST_SHEET_NAME: 'SHEET_NAME',
      STAGE:                       nil
    }

    ClimateControl.modify(env, &example)
  end
end
