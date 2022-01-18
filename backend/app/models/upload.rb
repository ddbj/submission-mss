class Upload < ApplicationRecord
  belongs_to :submission

  has_many_attached :files

  def copy_flles_to_submissions_dir
    return if copied?

    base = Pathname.new(ENV.fetch('SUBMISSIONS_DIR'))
    work = base.join('.work', submission.mass_id, dirname)
    dest = base.join(submission.mass_id)

    work.mkpath

    files.each do |attachment|
      work.join(attachment.filename.to_s).open 'wb' do |f|
        attachment.download do |chunk|
          f.write chunk
        end
      end
    end

    FileUtils.move work, dest.tap(&:mkpath)

    update! copied: true
  end

  def dirname
    created_at.strftime('%Y%m%d-%H%M%S')
  end
end
