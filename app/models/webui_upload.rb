class WebuiUpload < ApplicationRecord
  include UploadVia

  # Said two things at once and could only be seen from here, so both moved:
  # whether the files were copied is on the upload now, and whether the blobs
  # were let go is asked of the attachments. Ignored rather than dropped, so
  # that the containers still serving during the deploy that stops writing it
  # are not inserting a column this one has taken away.
  self.ignored_columns = %i[copied]

  has_many_attached :files

  # The signed IDs come from a direct upload this submitter just made, so an
  # empty list means nothing was uploaded; one we cannot verify was never issued
  # by us; and one whose blob has since been swept up as unattached is a request
  # that sat for days. None of them leaves anything to copy.
  def self.from_params(files: nil, **)
    raise Upload::Malformed, 'files is missing' if files.blank?

    new(files:)
  rescue ActiveSupport::MessageVerifier::InvalidSignature, ActiveRecord::RecordNotFound
    raise Upload::Malformed, 'files holds a signed ID we cannot make a file out of'
  end

  def copy_files_to_submissions_dir
    stage_files do |work|
      files.each do |attachment|
        work.join(attachment.filename.to_s).open 'wb' do |f|
          attachment.download do |chunk|
            f.write chunk
          end
        end
      end
    end

    # Active Storage is where the submitter's files wait to be fetched, not
    # where they are kept: with them in the submission directory it has nothing
    # left to hold. Here and now rather than left to a job of its own, so that
    # a storage which will not let go is the copy's failure, retried with it --
    # a purge that quietly gave up leaves blobs no sweep can reach, since a
    # sweep only takes the ones nothing is attached to.
    files.purge
  end

  def source_file_names
    files.blobs.map { _1.filename.to_s }.sort
  end

  def job_ids = nil
end
