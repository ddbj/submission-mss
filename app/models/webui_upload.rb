class WebuiUpload < ApplicationRecord
  include UploadVia

  has_many_attached :files

  delegate :submission, to: :upload

  def self.from_params(files:, **)
    new(files:)
  end

  def copy_files_to_submissions_dir
    return if copied?

    work = submission.root_dir.join("../.work/#{submission.mass_id}-#{upload.timestamp}")
    work.mkpath

    files.each do |attachment|
      work.join(attachment.filename.to_s).open "wb" do |f|
        attachment.download do |chunk|
          f.write chunk
        end
      end
    end

    upload.files_dir.dirname.mkpath
    work.rename upload.files_dir

    update! copied: true, files: []
  end

  def dfast_job_ids
    nil
  end
end
