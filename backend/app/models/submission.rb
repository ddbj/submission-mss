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

  def mass_id
    "NSUB#{id.to_s.rjust(6, '0')}"
  end

  def to_working_sheet_row
    {
      mass_id:                    mass_id,
      curator:                    nil,
      created_date:               created_at.to_date,
      status:                     nil,
      description:                description,
      contact_person_email:       contact_person.email,
      contact_person_full_name:   contact_person.full_name,
      contact_person_affiliation: contact_person.affiliation,
      other_person:               other_people.order(:position).map(&:email_address_with_name).join('; '),
      dway_account:               user.id_token.fetch('preferred_username'),
      data_arrival_date:          uploads.map(&:timestamp).join('; '),
      check_start_date:           nil,
      finish_date:                nil,
      sequencer:                  sequencer_text,
      annotation_pipeline:        dfast? ? 'DFAST' : nil,
      hup:                        hold_date || 'non-HUP',
      tpa:                        tpa?,
      data_type:                  data_type.upcase,
      total_entry:                entries_count,
      accession:                  nil,
      prefix_count:               nil,
      div:                        nil,
      bioproject:                 nil,
      biosample:                  nil,
      drr:                        nil,
      language:                   email_language,
      mail_j:                     nil,
      mail_e:                     nil,
      memo:                       nil
    }
  end
end
