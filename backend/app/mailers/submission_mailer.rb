class SubmissionMailer < ApplicationMailer
  def submitter_confirmation
    @submission = params[:submission]

    I18n.with_locale @submission.email_language do
      mail(
        to:      @submission.contact_person.email_address_with_name,
        cc:      @submission.other_people.order(:position).map(&:email_address_with_name),
        subject: "[DDBJ:#{@submission.mass_id}] #{@submission.data_type_text}"
      )
    end
  end

  def curator_notification
    @submission = params[:submission]
    @row        = @submission.to_working_sheet_row

    mail(
      to:      ApplicationMailer.default_params.fetch(:from),
      subject: "[DDBJ:#{@submission.mass_id}] #{@submission.data_type_text}"
    )
  end
end
