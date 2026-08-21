module ExtractionUpload
  extend ActiveSupport::Concern

  include UploadVia

  class_methods do
    # The extraction is named by an ID the submitter hands us, so look for it
    # among their own: anyone else's would otherwise have its files copied into
    # this submission. One that is still being read, or was turned down, holds
    # nothing worth copying and is out of reach for the same reason.
    def from_params(user:, extraction_id:, **)
      new(extraction: reflect_on_association(:extraction).klass.fulfilled.where(user:).find(extraction_id))
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
