class CopySubmissionFilesJob < ApplicationJob
  queue_as :default

  def perform(submission)
    output_dir = Pathname.new(ENV.fetch('SUBMISSIONS_DIR'))
    timestamp  = submission.created_at.strftime('%Y%m%d')
    work       = output_dir.join('.work', submission.mass_id, timestamp)
    dest       = output_dir.join(submission.mass_id)

    work.mkpath

    submission.files.each do |attachment|
      work.join(attachment.filename.to_s).open 'wb' do |f|
        attachment.download do |chunk|
          f.write chunk
        end
      end
    end

    FileUtils.move work, dest.tap(&:mkpath)

    submission.files.purge
  end
end
