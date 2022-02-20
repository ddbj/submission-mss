class Submissions::UploadsController < ApplicationController
  def create
    submission = current_user.submissions.find_by!(mass_id: params.require(:submission_mass_id))
    upload     = submission.uploads.create!(params.permit(files: []))

    UploadJob.perform_later upload

    head :ok
  end
end
