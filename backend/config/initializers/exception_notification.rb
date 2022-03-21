require 'exception_notification/rails'

ExceptionNotification.configure do |config|
  if recipients = ENV['EXCEPTION_RECIPIENTS']
    config.add_notifier :email, **{
      sender_address:       ENV.fetch('CURATOR_ML_ADDRESS'),
      exception_recipients: recipients.split(','),
      mailer_parent:        'ApplicationMailer'
    }
  end
end
