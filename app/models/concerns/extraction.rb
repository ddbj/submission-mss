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

    scope :fulfilled, -> { where(state: 'fulfilled') }

    # The gathered files are this extraction's alone. Nothing can find them
    # once it is gone, so they go with it.
    after_destroy_commit :remove_working_dir
  end

  # Lets the gathered files go while keeping the extraction itself: an upload
  # made from one still names the jobs its files came from.
  def discard_files
    # The directory goes first: what is left of it afterwards is something we
    # could not remove, and once the records are gone there is nothing left
    # anywhere that says it is there.
    remove_working_dir

    files.destroy_all
  end

  def working_dir
    dir  = Rails.application.config_for(:app).extracts_dir!
    name = self.class.name.delete_suffix('Extraction').underscore.dasherize

    Pathname.new(dir).join("#{name}-#{id}")
  end

  private

  def remove_working_dir
    working_dir.rmtree

    # rmtree is rm_rf, which reports nothing at all -- not a missing directory,
    # which is what we want, and not one it could not remove, which we do.
    raise "could not remove #{working_dir}" if working_dir.exist?
  end

  def normalize_path(path)
    path.to_s.gsub(%r{[/ ]}, '/' => '__', ' ' => '_')
  end
end
