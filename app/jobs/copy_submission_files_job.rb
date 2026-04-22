class CopySubmissionFilesJob < ApplicationJob
  queue_as :default

  def perform(upload)
    upload.via.copy_files_to_submissions_dir
  end
end
