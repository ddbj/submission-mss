class Upload < ApplicationRecord
  belongs_to :submission

  has_many_attached :files

  def copy_files_to_submissions_dir
    return if copied?

    work = submission.root_dir.dirname.join(".work/#{submission.mass_id}-#{timestamp}")
    work.mkpath

    files.each do |attachment|
      work.join(attachment.filename.to_s).open 'wb' do |f|
        attachment.download do |chunk|
          f.write chunk
        end
      end
    end

    files_dir.dirname.mkpath
    work.rename files_dir

    update! copied: true
  end

  def files_dir
    submission.root_dir.join(timestamp)
  end

  def timestamp
    created_at.strftime('%Y%m%d-%H%M%S')
  end
end
