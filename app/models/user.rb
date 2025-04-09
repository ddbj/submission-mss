class User < ApplicationRecord
  has_many :submissions,                dependent: :destroy
  has_many :dfast_extractions,          dependent: :destroy
  has_many :mass_directory_extractions, dependent: :destroy
end
