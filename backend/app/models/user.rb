class User < ApplicationRecord
  class SymbolizedJson < ActiveRecord::Type::Json
    def deserialize(...)
      super(...)&.symbolize_keys
    end
  end

  has_many :submissions, dependent: :destroy
  has_many :extractions, dependent: :destroy

  has_many :dfast_extractions
  has_many :mass_directory_extractions

  attribute :id_token, SymbolizedJson.new
end
