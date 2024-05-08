# Preview all emails at http://localhost:3000/rails/mailers/complete_submission

class SubmissionPreview < ActionMailer::Preview
  def submitter_confirmation
    submission = Submission.order(id: :desc).offset(params[:last] || 0).take!

    submission.email_language = I18n.locale

    SubmissionMailer.with(submission: submission).submitter_confirmation
  end
end
