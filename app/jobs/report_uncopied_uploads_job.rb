class ReportUncopiedUploadsJob < ApplicationJob
  # An upload whose files never reached the submission directory. The submitter
  # was told they sent them and the curator has nothing to open, and nothing
  # says so: the copy runs once, and a failure leaves it in the failed list for
  # somebody to notice.
  class UncopiedUpload < StandardError; end

  # Files that were copied and are not where they were put -- with the
  # submission they belong to still standing, or copied recently enough that
  # nobody can have finished with it. Either way this is the ground they were
  # standing on rather than anything about the upload.
  class VanishedFiles < StandardError; end

  # Files that arrived without the blobs they came in being let go. Active
  # Storage is a waiting room; these are sitting in it with nowhere to be, and
  # no sweep reaches them -- a sweep takes the blobs nothing is attached to.
  class UnreleasedBlobs < StandardError; end

  # More of one of those than anybody is going to work through by hand. Said
  # without the number in it, so that it stays one thing to answer for however
  # far it spreads.
  class TooMany < StandardError; end

  # Long enough that an upload still on its way is not mistaken for one that
  # will never arrive.
  GRACE = 1.day

  # How recently the copy has to have happened for the directory still being
  # there to be something we can insist on. Curators tidy away the submissions
  # they have dealt with, and being dealt with takes a while; nobody tidies
  # away this week's. So a directory gone from under a fresh copy is the
  # filesystem, and one gone from under an old copy is somebody's housekeeping.
  FRESH = 30.days

  # Named one at a time up to here, and counted past it.
  INDIVIDUALLY = 20

  queue_as :default

  def perform
    # Oldest first, so that the ones named when there are more than can be
    # named keep their place: an upload nobody has got to yet is the same thing
    # to answer for tomorrow, not a fresh one because the order came up
    # differently.
    uploads = Upload.includes(:submission).where(created_at: ..GRACE.ago).order(:created_at).to_a

    report_each uploads.reject { _1.copied? }, UncopiedUpload do
      "the files of #{name_of(_1)} never reached the submission"
    end

    report_each vanished(uploads), VanishedFiles do
      "the files of #{name_of(_1)} were copied, and are not where they were put"
    end

    report_each unclaimed(uploads), UnreleasedBlobs do
      "the files of #{name_of(_1)} arrived, but the blobs they came in were never let go"
    end
  end

  private

  # Naming stops being useful long before it stops being possible, so past a
  # point they are counted instead -- counted rather than dropped, and each kind
  # counted on its own. A pile of one of them is no reason to go quiet about the
  # single upload of another that somebody could still do something for.
  #
  # The count goes first. What is behind this queues the events and drops what
  # it cannot keep up with, and of everything said about a night like that, the
  # one line saying how big it is has to be the one that gets through.
  def report_each(candidates, error_class)
    if candidates.size > INDIVIDUALLY
      report TooMany.new("more uploads with this the matter with them than anybody will take one at a time: #{error_class.name.demodulize}"),
             count: candidates.size
    end

    candidates.first(INDIVIDUALLY).each { report error_class.new(yield(_1)) }
  end

  # Copied, and the files are not there. Told apart from a curator having
  # tidied the submission away by what they leave: they take the directory the
  # whole submission lives in, and they only take submissions they have
  # finished with, which takes a while. So a submission still standing without
  # its files is the ground moving whenever it happened, and one that is gone
  # entirely is only worth asking about while it is too recent to have been
  # anybody's housekeeping.
  def vanished(uploads)
    uploads.select {
      next false unless _1.copied_at? && !_1.files_dir.exist?

      _1.submission.root_dir.exist? || _1.copied_at.after?(FRESH.ago)
    }
  end

  # Copied, and still holding the blobs it was copied from. Asked of the
  # attachments themselves, in one query rather than one apiece: a flag set
  # alongside the purge would say the blobs had been let go however far the
  # purge actually got.
  #
  # Only a direct upload has any. The ids are of webui_uploads rows, and every
  # other way of arriving numbers its own table from one, so without asking
  # which way this arrived the two would be read as the same upload.
  def unclaimed(uploads)
    still_held = ActiveStorage::Attachment.where(record_type: 'WebuiUpload', name: 'files').pluck(:record_id).to_set

    uploads.select { _1.webui_upload? && still_held.include?(_1.via_id) && _1.copied? }
  end

  # Named the same way every night, so that each upload is one thing to answer
  # for rather than a sentence that reads differently as they come and go.
  def name_of(upload)
    "upload #{upload.submission.mass_id}/#{upload.files_dir_name}"
  end

  def report(error, **context)
    Rails.error.report error, handled: true, context:
  end
end
