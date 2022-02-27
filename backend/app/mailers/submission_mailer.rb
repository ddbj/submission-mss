class SubmissionMailer < ApplicationMailer
  def submitter_confirmation
    @submission = params[:submission]

    I18n.with_locale @submission.email_language do
      mail(
        to:      email_address_with_name(*@submission.user.id_token.values_at(:email, :name)),
        cc:      filter_recipients_by_allowed_domains(@submission).map(&:email_address_with_name),
        subject: "[DDBJ:#{@submission.mass_id}] #{@submission.data_type_text}"
      )
    end
  end

  def curator_notification
    @submission = params[:submission]
    @row        = WorkingList.instance.to_row(@submission)

    mail(
      to:      ApplicationMailer.default_params.fetch(:from),
      subject: "[DDBJ:#{@submission.mass_id}] #{@submission.data_type_text}"
    )
  end

  private

  def filter_recipients_by_allowed_domains(submission)
    recipients = [
      submission.contact_person,
      *submission.other_people.order(:position)
    ]

    return recipients unless allowed_domains = ENV['MAIL_ALLOWED_DOMAINS']&.split(',')

    recipients.select {|recipient|
      allowed_domains.any? {|domain| recipient.email.end_with?("@#{domain}") }
    }
  end
end
