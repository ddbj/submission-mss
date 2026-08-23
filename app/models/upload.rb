class Upload < ApplicationRecord
  # A request names the way its files arrive and carries what that way needs.
  # Both come from the submitter, so a way we do not have, or one left without
  # its parameters, is answered as a bad payload rather than crashed on.
  class Malformed < StandardError; end

  VIA = {
    webui:          'WebuiUpload',
    dfast:          'DfastUpload',
    mass_directory: 'MassDirectoryUpload',
    ggs:            'GgsUpload'
  }

  def self.build_via(via: nil, **params)
    VIA.fetch(via.to_s.to_sym) { raise Malformed, "unknown via: #{via.inspect}" }.constantize.from_params(**params)
  end

  TIMESTAMP_FORMAT = '%Y%m%d-%H%M%S'

  private_constant :TIMESTAMP_FORMAT

  belongs_to :submission

  delegated_type :via, types: VIA.values, dependent: :destroy

  # The name of the directory a submission is handed its files in, which is
  # also the arrival date the curator sheet gives and what the notification
  # mail sends them to. Settled once, when the upload is made: nothing that
  # happens later can move a directory somebody has already been sent to.
  attr_readonly :files_dir_name

  before_create :assign_files_dir_name

  # The files this upload consists of. They are copied into place in the
  # background, in one move, so until that has happened the names are known
  # only where they came from.
  #
  # Everything in the directory, rather than everything with a dot in its name,
  # and in an order rather than the one the directory happens to hold them in.
  # Only the staging writes there and it writes the files as they were sent, so
  # what is in there is what the upload consists of -- extension or no, leading
  # dot or no.
  def file_names
    names = files_dir.exist? ? Dir.children(files_dir).sort : []

    names.presence || via.source_file_names
  end

  def files_dir
    submission.root_dir.join(files_dir_name)
  end

  # Whether the files were handed over. The directory in place is the plain
  # evidence, but it sits on a filesystem curators work on too, and one tidied
  # away long after the submission was dealt with says nothing about whether it
  # was ever filled. So the copy says so itself as it lands, and that no later
  # tidying can take back.
  #
  # The directory still counts, for the uploads that were copied before anything
  # was written down.
  #
  # The trade: files that were copied and then lost -- a restore that came back
  # short, a volume mounted somewhere else -- read as handed over, because from
  # here that is indistinguishable from a curator having tidied them away. What
  # tells those apart is how long ago the copy was, and the nightly report asks
  # that of the recent ones separately.
  def copied?
    copied_at? || files_dir.exist?
  end

  def via_ident
    VIA.key(via.class.name)
  end

  private

  # Two uploads of one submission made in the same second would be handed the
  # same directory, and the second copied over the first. Tell them apart with a
  # suffix, which leaves the moment they arrived legible wherever the name is
  # read as one.
  def assign_files_dir_name
    # The submission is held for the rest of this transaction, so that two
    # uploads arriving at once cannot both find the same name free: the second
    # waits here, and reads the first once it has landed. Held through a query
    # rather than submission.lock!, which reloads the record and would drop
    # whatever is still being saved alongside us.
    Submission.lock.where(id: submission_id).pick(:id)

    base  = created_at.strftime(TIMESTAMP_FORMAT)
    taken = Upload.where(submission_id:).pluck(:files_dir_name)

    self.files_dir_name = (0..).lazy.map {
      _1.zero? ? base : "#{base}-#{_1}"
    }.find {
      taken.exclude?(_1)
    }
  end
end
