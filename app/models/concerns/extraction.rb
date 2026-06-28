module Extraction
  extend ActiveSupport::Concern

  class Error < StandardError
    def initialize(id, **data)
      super()

      @id   = id
      @data = data
    end

    attr_reader :id, :data
  end

  included do
    belongs_to :user

    has_many :files, dependent: :destroy, class_name: "#{name}File", foreign_key: :extraction_id
  end

  def working_dir
    dir  = Rails.application.config_for(:app).extracts_dir!
    name = self.class.name.delete_suffix('Extraction').underscore.dasherize

    Pathname.new(dir).join("#{name}-#{id}")
  end

  private

  def normalize_path(path)
    path.to_s.gsub(%r{[/ ]}, '/' => '__', ' ' => '_')
  end
end
