class SubmissionsController < ApplicationController
  before_action :require_authentication

  def create
    @submission = current_user.submissions.create!(submission_params.except(:contact_person)) {|submission|
      submission.build_contact_person(submission_params[:contact_person])
    }

    CompleteSubmissionJob.perform_later @submission
  end

  private

  def submission_params
    params.require(:submission).permit(
      :data_type,
      :email_language,
      files: [],

      contact_person: [
        :email,
        :full_name,
        :affiliation
      ]
    )
  end
end
