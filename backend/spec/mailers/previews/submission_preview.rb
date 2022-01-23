# Preview all emails at http://localhost:3000/rails/mailers/complete_submission

class SubmissionPreview < ActionMailer::Preview
  def confirmation
    submission = Submission.order(id: :desc).offset(params[:last] || 0).first

    SubmissionMailer.with(submission: submission).confirmation
  end
end
