class MailDeliveryJob < ActionMailer::MailDeliveryJob
  retry_on Net::OpenTimeout, wait: :polynomially_longer
end
