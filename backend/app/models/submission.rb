class Submission < ApplicationRecord
  extend Enumerize

  belongs_to :user

  has_many_attached :files

  YAML.load_file(Rails.root.join('../config/enums.yml')).deep_symbolize_keys.then do |enums|
    enumerize :data_type, in: enums.fetch(:data_types).map {|type| type.fetch(:key) }, i18n_scope: 'mssform.data_types'
    enumerize :sequencer, in: enums.fetch(:sequencers).map {|type| type.fetch(:key) }, i18n_scope: 'mssform.sequencers'
  end

  def mass_id
    "NSUB#{id.to_s.rjust(6, '0')}"
  end
end
