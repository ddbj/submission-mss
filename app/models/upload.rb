class Upload < ApplicationRecord
  VIA = {
    webui:          'WebuiUpload',
    dfast:          'DfastUpload',
    mass_directory: 'MassDirectoryUpload',
    ggs:            'GgsUpload'
  }

  def self.find_via(ident)
    VIA.fetch(ident.to_sym).constantize
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
