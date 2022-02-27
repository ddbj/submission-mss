class User < ApplicationRecord
  class SymbolizedJson < ActiveRecord::Type::Json
    def deserialize(...)
      super(...)&.symbolize_keys
    end
  end

  has_many :submissions, dependent: :destroy

  attribute :id_token, SymbolizedJson.new
end
