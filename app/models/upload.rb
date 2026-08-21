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

  belongs_to :submission

  delegated_type :via, types: VIA.values, dependent: :destroy

  # The files this upload consists of. They are copied into place in the
  # background, in one move, so until that has happened the names are known
  # only where they came from.
  def file_names
    Dir.glob('*.*', base: files_dir).presence || via.source_file_names
  end

  def files_dir
    submission.root_dir.join(timestamp)
  end

  def timestamp
    created_at.strftime('%Y%m%d-%H%M%S')
  end

  def via_ident
    VIA.key(via.class.name)
  end
end
