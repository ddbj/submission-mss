class Upload < ApplicationRecord
  belongs_to :submission

  has_many_attached :files

  def copy_flles_to_submissions_dir
    return if copied?

    work = submissions_dir.join('.work', "#{submission.mass_id}-#{timestamp}")
    work.mkpath

    files.each do |attachment|
      work.join(attachment.filename.to_s).open 'wb' do |f|
        attachment.download do |chunk|
          f.write chunk
        end
      end
    end

    directory_path.dirname.mkpath
    FileUtils.move work, directory_path

    update! copied: true
  end

  def directory_path
    submissions_dir.join(submission.mass_id, timestamp)
  end

  def timestamp
    created_at.strftime('%Y%m%d-%H%M%S')
  end

  private

  def submissions_dir
    Pathname.new(ENV.fetch('SUBMISSIONS_DIR'))
  end
end
