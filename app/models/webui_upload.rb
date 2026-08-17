class WebuiUpload < ApplicationRecord
  include UploadVia

  has_many_attached :files

  def self.from_params(files:, **)
    new(files:)
  end

  def copy_files_to_submissions_dir
    return if copied?

    stage_files do |work|
      files.each do |attachment|
        work.join(attachment.filename.to_s).open 'wb' do |f|
          attachment.download do |chunk|
            f.write chunk
          end
        end
      end
    end

    update! copied: true, files: []
  end

  def source_file_names
    files.blobs.map { _1.filename.to_s }.sort
  end

  def job_ids = nil
end
