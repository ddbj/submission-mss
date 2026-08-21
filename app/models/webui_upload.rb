class WebuiUpload < ApplicationRecord
  include UploadVia

  has_many_attached :files

  # The signed IDs come from a direct upload this submitter just made, so an
  # empty list means nothing was uploaded, and one we cannot verify was never
  # issued by us. Neither leaves anything to copy.
  def self.from_params(files: nil, **)
    raise Upload::Malformed, 'files is missing' if files.blank?

    new(files:)
  rescue ActiveSupport::MessageVerifier::InvalidSignature
    raise Upload::Malformed, 'files holds a signed ID we did not issue'
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
