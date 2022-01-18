class ApplicationMailer < ActionMailer::Base
  layout 'mailer'

  default from: email_address_with_name('mass@ddbj.nig.ac.jp', 'DDBJ Mass Submission System (MSS)')

  after_action do
    if stage = ENV['STAGE'] and stage != 'production'
      mail.subject.prepend "[#{stage.titlecase}] "
    end
  end
end
