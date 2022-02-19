class Submissions::UploadsController < ApplicationController
  def create
    id         = params[:submission_mass_id].delete_prefix('NSUB')
    submission = current_user.submissions.find(id)

    submission.uploads.create! params.permit(files: [])

    head :ok
  end
end
