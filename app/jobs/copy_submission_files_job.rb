class CopySubmissionFilesJob < ApplicationJob
  queue_as :default

  def perform(submission)
    dest = Pathname.new(ENV.fetch('SUBMISSIONS_DIR')).join(submission.mass_id, submission.created_at.strftime('%Y%m%d'))
    dest.mkpath

    submission.files.each do |attachment|
      dest.join(attachment.filename.to_s).open 'wb' do |f|
        attachment.download do |chunk|
          f.write chunk
        end
      end
    end
  end
end
