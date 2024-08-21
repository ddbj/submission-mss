class UploadJob < ApplicationJob
  queue_as :default

  retry_on Google::Apis::ServerError

  def perform(upload)
    upload.via.copy_files_to_submissions_dir

    submission = upload.submission

    WorkingList.instance.update_data_arrival_date submission

    SubmissionMailer.with(submission:).submitter_confirmation.deliver_later
    SubmissionMailer.with(submission:).curator_notification.deliver_later
  end
end
