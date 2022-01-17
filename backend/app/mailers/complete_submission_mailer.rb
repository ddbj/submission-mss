class CompleteSubmissionMailer < ApplicationMailer
  default cc: -> { ENV['SUBMISSION_MAIL_CC']&.split(',') }

  def for_submitter
    @submission = params[:submission]

    email, full_name = @submission.contact_person.values_at(:email, :full_name)

    I18n.with_locale @submission.email_language do
      mail(
        to:            email_address_with_name(email, full_name),
        subject:       "[DDBJ:#{@submission.mass_id}] #{@submission.data_type_text}#{@submission.short_title.presence&.prepend(': ')}",
        template_name: 'for_submitter/not_uploaded'
      )
    end
  end
end
