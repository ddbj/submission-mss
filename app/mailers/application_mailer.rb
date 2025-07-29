class ApplicationMailer < ActionMailer::Base
  layout 'mailer'

  default from: email_address_with_name('mass@ddbj.nig.ac.jp', 'DDBJ Mass Submission System (MSS)')

  after_action do
    mail.subject.prepend '[Staging] ' if Rails.env.staging?
  end
end
