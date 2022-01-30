class Submission < ApplicationRecord
  extend Enumerize

  belongs_to :user

  has_many :uploads,        dependent: :destroy
  has_one  :contact_person, dependent: :destroy
  has_many :other_people,   dependent: :destroy

  YAML.load_file(Rails.root.join('../config/enums.yml')).deep_symbolize_keys.then do |enums|
    enumerize :data_type, in: enums.fetch(:data_types).map {|type| type.fetch(:key) }, i18n_scope: 'mssform.data_types'
    enumerize :sequencer, in: enums.fetch(:sequencers).map {|type| type.fetch(:key) }, i18n_scope: 'mssform.sequencers'
  end

  enumerize :email_language, in: %i(ja en)

  def mass_id
    "NSUB#{id.to_s.rjust(6, '0')}"
  end
end
