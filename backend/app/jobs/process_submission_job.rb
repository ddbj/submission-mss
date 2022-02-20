class ProcessSubmissionJob < ApplicationJob
  queue_as :default

  def perform(submission)
    submission.uploads.first&.copy_files_to_submissions_dir

    WorkingList.instance.add_new_submission submission

    SubmissionMailer.with(submission:).submitter_confirmation.deliver_later
    SubmissionMailer.with(submission:).curator_notification.deliver_later
  end
end
