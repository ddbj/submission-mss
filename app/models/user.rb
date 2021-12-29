class User < ApplicationRecord
  has_many :submissions, dependent: :destroy
end
