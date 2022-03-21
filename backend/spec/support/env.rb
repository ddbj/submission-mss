RSpec.configure do |config|
  config.around do |example|
    Dir.mktmpdir do |dir|
      env = {
        CURATOR_ML_ADDRESS:          'Admin <mssform@example.com>',
        MAIL_ALLOWED_DOMAINS:        nil,
        MSSFORM_URL:                 'http://mssform.example.com',
        MSS_WORKING_LIST_SHEET_ID:   'SHEET_ID',
        MSS_WORKING_LIST_SHEET_NAME: 'SHEET_NAME',
        OPENID_CLIENT_ID:            'CLIENT_ID',
        STAGE:                       nil,
        SUBMISSIONS_DIR:             dir
      }

      ClimateControl.modify(env, &example)
    end
  end
end
