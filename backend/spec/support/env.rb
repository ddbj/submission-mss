RSpec.configure do |config|
  config.around do |example|
    env = {
      MSSFORM_URL: 'http://mssform.example.com'
    }

    ClimateControl.modify(env, &example)
  end
end
