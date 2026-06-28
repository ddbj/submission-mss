class GgsExtraction < ApplicationRecord
  include Extraction

  EXTENSIONS = %w[ann fa].freeze

  UUID_FORMAT = /\A\h{8}-\h{4}-\h{4}-\h{4}-\h{12}\z/

  validates :ggs_job_ids, presence: true

  validate do
    next if ggs_job_ids.blank?

    errors.add :ggs_job_ids, :invalid unless ggs_job_ids.all? { _1.match?(UUID_FORMAT) }
  end

  def prepare_files
    working_dir.mkpath

    ActiveRecord::Base.transaction do
      ggs_job_ids.uniq.each do |job_id|
        copy_files job_id
      end
    end
  end

  private

  def copy_files(job_id)
    src_dir = job_output_dir(job_id)

    raise Extraction::Error.new(:directory_not_found, job_id:) unless src_dir.directory?

    dest_dir = working_dir.join(job_id).tap(&:mkpath)

    Pathname.glob("*.{#{EXTENSIONS.join(',')}}", base: src_dir).each do |rel|
      name = normalize_path(rel)

      FileUtils.cp src_dir.join(rel), dest_dir.join(name)

      files.create!(
        name:,
        parsing:    true,
        ggs_job_id: job_id
      )
    end
  end

  def job_output_dir(job_id)
    template = Rails.application.config_for(:app).ggs_jobs_dir_template!
    path     = template.gsub('{job_id}', job_id)

    raise "malformed directory path: #{path}" unless path == File.expand_path(path)

    Pathname.new(path)
  end
end
