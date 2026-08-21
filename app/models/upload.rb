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
  def file_names
    Dir.glob('*.*', base: files_dir).presence || via.source_file_names
  end

  def files_dir
    submission.root_dir.join(files_dir_name)
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
