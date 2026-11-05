class User < ApplicationRecord
  # What the identity provider told us is not enough to make a user of.
  class IncompleteClaims < StandardError; end

  has_many :submissions,                dependent: :destroy
  has_many :dfast_extractions,          dependent: :destroy
  has_many :mass_directory_extractions, dependent: :destroy
  has_many :ggs_extractions,            dependent: :destroy

  # The user the realm knows as `uid` (its preferred_username), made on first
  # sight. The address is used only to make one -- without it there would be no
  # one to tell about their submissions. Whether an existing user's address is
  # brought up to date is the caller's to decide.
  def self.from_claims!(uid:, email:)
    raise IncompleteClaims, 'no uid' unless uid.is_a?(String) && uid.present?

    find_by(uid:) || begin
      raise IncompleteClaims, "no email for the new user #{uid.truncate(64).inspect}" unless email.is_a?(String) && email.present?

      # Two first requests from the same newcomer at once: the loser finds the
      # winner's.
      create_or_find_by!(uid:) { it.email = email }
    end
  end
end
