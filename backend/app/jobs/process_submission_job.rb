class ProcessSubmissionJob < ApplicationJob
  queue_as :default

  def perform(upload)
    upload.via.copy_files_to_submissions_dir

    WorkingList.instance.add_new_submission upload.submission

    SubmissionMailer.with(submission: upload.submission).submitter_confirmation.deliver_later
    SubmissionMailer.with(submission: upload.submission).curator_notification.deliver_later
  end
end
