class ApplicationMailer < ActionMailer::Base
  layout "mailer"

  default from: email_address_with_name("mass@ddbj.nig.ac.jp", "DDBJ Mass Submission System (MSS)")

  after_action do
    if env = ENV["SENTRY_CURRENT_ENV"] and env != "production"
      mail.subject.prepend "[#{env.titlecase}] "
    end
  end
end
