class ApplicationMailer < ActionMailer::Base
  layout "mailer"

  default from: -> { ENV.fetch("CURATOR_ML_ADDRESS") }

  after_action do
    if stage = ENV["STAGE"] and stage != "production"
      mail.subject.prepend "[#{stage.titlecase}] "
    end
  end
end
