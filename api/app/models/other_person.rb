class OtherPerson < ApplicationRecord
  include EmailAddressWithName

  belongs_to :submission
end
