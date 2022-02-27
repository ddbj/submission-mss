RSpec.configure do |config|
  config.around do |example|
    env = {
      MAIL_ALLOWED_DOMAINS: nil,
      MSSFORM_URL:          'http://mssform.example.com',
      STAGE:                nil
    }

    ClimateControl.modify(env, &example)
  end
end
