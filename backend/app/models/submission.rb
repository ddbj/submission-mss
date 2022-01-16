class Submission < ApplicationRecord
  belongs_to :user

  has_one :contact_person

  has_many_attached :files

  def mass_id
    "NSUB#{id.to_s.rjust(6, '0')}"
  end
end
