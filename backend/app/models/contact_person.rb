class ContactPerson < ApplicationRecord
  include EmailAddressWithName

  belongs_to :submission
end
