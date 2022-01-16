class Submission < ApplicationRecord
  extend Enumerize

  belongs_to :user

  has_one :contact_person

  has_many_attached :files

  YAML.load_file(Rails.root.join('config/enums.yml')).then do |enums|
    enumerize :data_type, in: enums.fetch('data_types').keys, i18n_scope: 'mssform.data_types'
  end

  def mass_id
    "NSUB#{id.to_s.rjust(6, '0')}"
  end
end
