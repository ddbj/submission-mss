class CopySubmissionFilesJob < ApplicationJob
  queue_as :default

  # Until this has run, the blobs a direct upload made are the only copy of the
  # submitter's files, and nothing else will come for them: there is no route
  # that runs it again. So the ways a disk or a network lets us down are worth
  # another go rather than a place in the failed list -- including the storage
  # answering 503 while it restarts, and telling us an object is not there when
  # a volume server has yet to catch up. Copying is idempotent: a directory
  # already in place is left alone.
  #
  # The net is cast by where the trouble came from rather than by whether it
  # will pass, so a full disk is tried five times too. Six minutes to reach the
  # failed list is nothing against the day the sweep waits before asking after
  # an upload, and everything else still fails at once, where it can be seen.
  retry_on SystemCallError,                   wait: :polynomially_longer, attempts: 5
  retry_on Seahorse::Client::NetworkingError, wait: :polynomially_longer, attempts: 5
  retry_on Aws::Errors::ServiceError,         wait: :polynomially_longer, attempts: 5
  retry_on ActiveStorage::FileNotFoundError,  wait: :polynomially_longer, attempts: 5

  def perform(upload)
    upload.via.copy_files_to_submissions_dir
  end
end
