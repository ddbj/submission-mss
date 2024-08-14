class Submission < ApplicationRecord
  extend Enumerize

  belongs_to :user

  has_many :uploads,        dependent: :destroy
  has_one  :contact_person, dependent: :destroy
  has_many :other_people,   dependent: :destroy

  YAML.load_file(Rails.root.join("../config/enums.yml")).deep_symbolize_keys.then do |enums|
    enumerize :data_type,      in: enums.fetch(:data_types).map { _1.fetch(:key) }, i18n_scope: "mssform.data_types"
    enumerize :sequencer,      in: enums.fetch(:sequencers).map { _1.fetch(:key) }, i18n_scope: "mssform.sequencers"
    enumerize :email_language, in: enums.fetch(:locales).map    { _1.fetch(:key) }, i18n_scope: "mssform.locales"
  end

  def self.last_mass_id_seq
    last = Submission.select(:mass_id).order(mass_id: :desc).first

    last ? last.mass_id.delete_prefix("NSUB").to_i : 0
  end

  def root_dir
    Pathname.new(ENV.fetch("SUBMISSIONS_DIR")).join(mass_id)
  end

  def upload_disabled?
    root_dir.join("disable-upload").exist?
  end

  def set_mass_id(seq)
    self.mass_id = "NSUB#{seq.to_s.rjust(6, '0')}"
  end
end
