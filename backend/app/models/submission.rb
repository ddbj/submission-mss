class Submission < ApplicationRecord
  extend Enumerize

  belongs_to :user

  has_many :uploads,        dependent: :destroy
  has_one  :contact_person, dependent: :destroy
  has_many :other_people,   dependent: :destroy

  YAML.load_file(Rails.root.join('../config/enums.yml')).deep_symbolize_keys.then do |enums|
    enumerize :data_type,      in: enums.fetch(:data_types).map {|item| item.fetch(:key) }, i18n_scope: 'mssform.data_types'
    enumerize :sequencer,      in: enums.fetch(:sequencers).map {|item| item.fetch(:key) }, i18n_scope: 'mssform.sequencers'
    enumerize :email_language, in: enums.fetch(:locales).map    {|item| item.fetch(:key) }, i18n_scope: 'mssform.locales'
  end

  def root_dir
    Pathname.new(ENV.fetch('SUBMISSIONS_DIR')).join(mass_id)
  end

  def upload_disabled?
    root_dir.join('disable-upload').exist?
  end
end
