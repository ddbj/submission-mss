class CompleteSubmissionMailer < ApplicationMailer
  def for_submitter
    @submission = params[:submission]

    I18n.with_locale @submission.email_language do
      mail(
        to:            format_address(@submission.contact_person),
        cc:            @submission.other_people.map { format_address(_1) } + ENV['SUBMISSION_MAIL_CC'].to_s.split(','),
        subject:       "[DDBJ:#{@submission.mass_id}] #{@submission.data_type_text}#{@submission.short_title.presence&.prepend(': ')}",
        template_name: 'for_submitter/not_uploaded'
      )
    end
  end

  private

  def format_address(person)
    email, full_name = person.fetch_values('email', 'full_name')

    email_address_with_name(email, full_name)
  end
end
