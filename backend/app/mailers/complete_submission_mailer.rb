class CompleteSubmissionMailer < ApplicationMailer
  def for_submitter
    @submission = params[:submission]

    cc = [
      ApplicationMailer.default_params.fetch(:from),
      *@submission.other_people.map { format_address(_1) }
    ]

    I18n.with_locale @submission.email_language do
      mail(
        to:            format_address(@submission.contact_person),
        cc:,
        subject:       "[DDBJ:#{@submission.mass_id}] #{@submission.data_type_text}",
        template_name: 'for_submitter/not_uploaded'
      )
    end
  end

  private

  def format_address(person)
    email, full_name = person.fetch_values('email', 'full_name')

    ApplicationMailer.email_address_with_name(email, full_name)
  end
end
