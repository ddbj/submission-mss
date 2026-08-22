class ReportUncopiedUploadsJob < ApplicationJob
  # An upload whose files never reached the submission directory. The submitter
  # was told they sent them and the curator has nothing to open, and nothing
  # says so: the copy runs once, and a failure leaves it in the failed list for
  # somebody to notice.
  class UncopiedUpload < StandardError; end

  # Files that arrived without the blobs they came in being let go. Active
  # Storage is a waiting room; these are sitting in it with nowhere to be.
  class UnreleasedBlobs < StandardError; end

  # Too many at once is not a story about uploads. Said as one, so that a
  # submissions directory that is not where we left it does not arrive as
  # thousands of separate alarms.
  class NothingArrived < StandardError; end

  # Long enough that an upload still on its way is not mistaken for one that
  # will never arrive.
  GRACE = 1.day

  # Beyond this, they are not being reported one at a time.
  INDIVIDUALLY = 20

  queue_as :default

  def perform
    uploads = Upload.includes(:submission).where(created_at: ..GRACE.ago).to_a

    uncopied  = uploads.reject { _1.files_dir.exist? }
    unclaimed = uploads.select { _1.webui_upload? && _1.files_dir.exist? && !_1.via.copied? }

    if uncopied.size > INDIVIDUALLY
      report NothingArrived.new("#{uncopied.size} of #{uploads.size} uploads have no directory, which is more about where we are looking than about them")
    else
      uncopied.each  { report UncopiedUpload.new("the files of #{name_of(_1)} never reached the submission") }
      unclaimed.each { report UnreleasedBlobs.new("the files of #{name_of(_1)} arrived, but the blobs they came in were never let go") }
    end
  end

  private

  # Named the same way every night, so that each upload is one thing to answer
  # for rather than a sentence that reads differently as they come and go.
  def name_of(upload)
    "upload #{upload.submission.mass_id}/#{upload.files_dir_name}"
  end

  def report(error)
    Rails.error.report error, handled: true
  end
end
