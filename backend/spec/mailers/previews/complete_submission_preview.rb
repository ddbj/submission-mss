# Preview all emails at http://localhost:3000/rails/mailers/complete_submission

class CompleteSubmissionPreview < ActionMailer::Preview
  def for_submitter
    CompleteSubmissionMailer.with(submission: Submission.last).for_submitter
  end
end
