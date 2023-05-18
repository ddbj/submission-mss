class DfastUpload < ApplicationRecord
  include UploadVia

  def self.from_params(extraction_id:, **)
    new(extraction_id:)
  end

  belongs_to :extraction, class_name: 'DfastExtraction'

  def copy_files_to_submissions_dir
    upload.files_dir.mkpath

    extraction.files.find_each do |file|
      FileUtils.cp file.fullpath, upload.files_dir
    end
  end
end