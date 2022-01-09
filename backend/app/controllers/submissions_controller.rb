class SubmissionsController < ApplicationController
  before_action :require_authentication

  def create
    submission = current_user.submissions.create!(submission_params)

    CompleteSubmissionJob.perform_later submission

    render json: {
      submission: submission_params.merge(id: submission.mass_id)
    }
  end

  private

  def submission_params
    params.require(:submission).permit(files: [])
  end
end
