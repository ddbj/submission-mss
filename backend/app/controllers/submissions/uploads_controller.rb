class Submissions::UploadsController < ApplicationController
  def create
    submission = current_user.submissions.find_by!(mass_id: params[:submission_mass_id])

    if submission.upload_disabled?
      head :forbidden
      return
    end

    upload = submission.uploads.create!(
      via: Upload.find_via(upload_params[:via]).from_params(**upload_params.to_h.symbolize_keys)
    )

    UploadJob.perform_later upload

    head :ok
  end

  private

  def upload_params
    params.require(:upload).permit(
      :via,
      :extraction_id,

      files: []
    )
  end
end
