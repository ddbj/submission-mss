class Upload < ApplicationRecord
  VIA = {
    webui:          'WebuiUpload',
    dfast:          'DfastUpload',
    mass_directory: 'MassDirectoryUpload'
  }

  def self.find_via(ident)
    VIA.fetch(ident.to_sym).constantize
  end

  belongs_to :submission

  delegated_type :via, types: VIA.values, dependent: :destroy

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
