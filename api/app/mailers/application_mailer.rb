class ApplicationMailer < ActionMailer::Base
  layout "mailer"

  default from: -> { ENV.fetch("CURATOR_ML_ADDRESS") }

  after_action do
    if env = ENV["SENTRY_CURRENT_ENV"] and env != "production"
      mail.subject.prepend "[#{env.titlecase}] "
    end
  end
end
