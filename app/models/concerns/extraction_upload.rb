module ExtractionUpload
  extend ActiveSupport::Concern

  include UploadVia

  class_methods do
    def from_params(extraction_id:, **)
      new(extraction_id:)
    end
  end

  def copy_files_to_submissions_dir
    upload.files_dir.mkpath

    extraction.files.find_each do |file|
      FileUtils.cp file.fullpath, upload.files_dir
    end

    trim_annotation_fields!
  end
end
