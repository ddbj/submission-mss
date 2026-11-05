class Submissions::UploadsController < ApplicationController
  def create
    submission = current_user.submissions.find_by!(mass_id: params[:submission_mass_id])

    if submission.upload_disabled?
      head :forbidden
      return
    end

    # The portal keeps the versions of the ones it made, and would never hear of
    # files sent here.
    if submission.portal_managed? && !bearer_authenticated?
      head :forbidden
      return
    end

    upload = submission.uploads.create!(
      via: Upload.build_via(user: current_user, **upload_params.to_h.symbolize_keys)
    )

    UploadEventLog.append upload

    CopySubmissionFilesJob.perform_later upload
    UpdateWorkingListJob.perform_later   submission

    # The portal writes to them itself.
    unless submission.portal_managed?
      SubmissionMailer.with(submission:).submitter_confirmation.deliver_later
      SubmissionMailer.with(submission:).curator_notification.deliver_later
    end

    head :no_content
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
