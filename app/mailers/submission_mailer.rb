class SubmissionMailer < ApplicationMailer
  def submitter_confirmation
    @submission = params[:submission]

    I18n.with_locale @submission.email_language do
      mail(
        to:      @submission.user.email,
        cc:      filter_recipients_by_allowed_domains(@submission).map(&:email_address_with_name),
        subject: "[DDBJ:#{@submission.mass_id}] #{@submission.data_type_text}"
      )
    end
  end

  def curator_notification
    @submission = params[:submission]
    @row        = WorkingList.instance.to_row(@submission)

    mail(
      to:      ApplicationMailer.default.fetch(:from),
      subject: "[DDBJ:#{@submission.mass_id}] #{@submission.data_type_text}"
    )
  end

  private

  def filter_recipients_by_allowed_domains(submission)
    recipients = [
      submission.contact_person,
      *submission.other_people.order(:position)
    ]

    return recipients unless allowed_domains = Rails.application.config_for(:app).mail_allowed_domains&.split(",")

    recipients.select { |recipient|
      allowed_domains.any? { |domain| recipient.email.end_with?("@#{domain}") }
    }
  end
end
