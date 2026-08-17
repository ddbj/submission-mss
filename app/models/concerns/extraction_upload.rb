module ExtractionUpload
  extend ActiveSupport::Concern

  include UploadVia

  class_methods do
    def from_params(extraction_id:, **)
      new(extraction_id:)
    end
  end

  def copy_files_to_submissions_dir
    stage_files do |work|
      extraction.files.find_each do |file|
        FileUtils.cp file.fullpath, work
      end
    end
  end

  def source_file_names
    extraction.files.pluck(:name).sort
  end
end
