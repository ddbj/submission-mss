class CompleteSubmissionMailer < ApplicationMailer
  def for_submitter
    @submission = params[:submission]

    cc = [
      ApplicationMailer.default_params.fetch(:from),
      *@submission.other_people.order(:position).map(&:email_address_with_name)
    ]

    I18n.with_locale @submission.email_language do
      mail(
        to:            @submission.contact_person.email_address_with_name,
        cc:,
        subject:       "[DDBJ:#{@submission.mass_id}] #{@submission.data_type_text}",
        template_name: 'for_submitter/not_uploaded'
      )
    end
  end
end
