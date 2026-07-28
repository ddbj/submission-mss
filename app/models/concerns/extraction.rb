module Extraction
  extend ActiveSupport::Concern

  # DFAST/GGS job IDs are UUIDs that become path segments in the job's URL or
  # output directory. Reject malformed values so a stray space or truncated ID
  # can't crash the extraction with a URI parse error.
  UUID_FORMAT = /\A\h{8}-\h{4}-\h{4}-\h{4}-\h{12}\z/

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
