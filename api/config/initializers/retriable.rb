Retriable.configure do |config|
  config.contexts[:google] = {
    on: [
      Google::Apis::ServerError
    ],

    tries:         Rails.env.test? ? 1 : 10,
    base_interval: 1,
    multiplier:    2
  }
end
