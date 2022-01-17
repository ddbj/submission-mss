# Preview all emails at http://localhost:3000/rails/mailers/complete_submission

class CompleteSubmissionPreview < ActionMailer::Preview
  def for_submitter
    submission = Submission.order(id: :desc).offset(params[:last] || 0).first

    CompleteSubmissionMailer.with(submission: submission).for_submitter
  end
end
