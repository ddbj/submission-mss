module ExtractionUpload
  extend ActiveSupport::Concern

  include UploadVia

  class_methods do
    # The extraction is named by an ID the submitter hands us, so look for it
    # among their own: anyone else's would otherwise have its files copied into
    # this submission. One that is still being read, or was turned down, holds
    # nothing worth copying and is out of reach for the same reason.
    def from_params(user:, extraction_id: nil, **)
      raise Upload::Malformed, 'extraction_id is missing' if extraction_id.blank?

      extraction = extraction_class.fulfilled.where(user:).find(extraction_id)

      # Swept up since the submitter last looked at it. Left alone this would
      # copy an empty directory into place, and that copy is what says the
      # upload is done: the submission would be finished and empty.
      raise Upload::Malformed, "extraction #{extraction_id} has no files" if extraction.files.empty?

      new(extraction:)
    end

    def extraction_class = reflect_on_association(:extraction).klass
  end

  def copy_files_to_submissions_dir
    stage_files do |work|
      # Swept up between the upload being made and this running. Copying nothing
      # looks exactly like copying everything from here on, so say so instead.
      raise "#{extraction.class.name} #{extraction.id} has no files to copy" if extraction.files.empty?

      extraction.files.find_each do |file|
        FileUtils.cp file.fullpath, work
      end
    end
  end

  def source_file_names
    extraction.files.pluck(:name).sort
  end
end
