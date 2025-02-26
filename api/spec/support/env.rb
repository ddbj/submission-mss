RSpec.configure do |config|
  config.around do |example|
    Dir.mktmpdir do |mass_dir|
      Dir.mktmpdir do |submissions_dir|
        env = {
          MAIL_ALLOWED_DOMAINS:        nil,
          MASS_DIR_PATH_TEMPLATE:      mass_dir,
          MSS_WORKING_LIST_SHEET_ID:   "SHEET_ID",
          MSS_WORKING_LIST_SHEET_NAME: "SHEET_NAME",
          SUBMISSIONS_DIR:             submissions_dir,
          WEB_URL:                     "http://mssform.example.com"
        }

        ClimateControl.modify(env, &example)
      end
    end
  end
end
