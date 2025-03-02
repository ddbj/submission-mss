class User < ApplicationRecord
  def self.generate_api_key
    "mssform_#{Base62.encode(SecureRandom.random_number(2 ** 256))}"
  end

  has_many :submissions,                dependent: :destroy
  has_many :dfast_extractions,          dependent: :destroy
  has_many :mass_directory_extractions, dependent: :destroy

  before_create do |user|
    user.api_key = self.class.generate_api_key
  end
end
