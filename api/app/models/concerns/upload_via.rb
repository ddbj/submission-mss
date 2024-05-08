module UploadVia
  extend ActiveSupport::Concern

  included do
    has_one :upload, as: :via, touch: true, dependent: :destroy
  end
end
