class User < ApplicationRecord
  has_many :submissions,                dependent: :destroy
  has_many :dfast_extractions,          dependent: :destroy
  has_many :mass_directory_extractions, dependent: :destroy

  def token
    JWT.encode({ user_id: id }, Rails.application.secret_key_base, "HS512")
  end
end
