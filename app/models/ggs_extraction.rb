class GgsExtraction < ApplicationRecord
  include Extraction
  include ArchiveExtraction

  UUID_FORMAT = /\A\h{8}-\h{4}-\h{4}-\h{4}-\h{12}\z/

  validates :ggs_job_ids, presence: true

  validate do
    next if ggs_job_ids.blank?

    errors.add :ggs_job_ids, :invalid unless ggs_job_ids.all? { _1.match?(UUID_FORMAT) }
  end

  def prepare_files
    ActiveRecord::Base.transaction do
      ggs_job_ids.uniq.each do |job_id|
        copy_job_files job_id
      end
    end
  end

  private

  def copy_job_files(job_id)
    src_dir = job_output_dir(job_id)

    raise Extraction::Error.new(:directory_not_found, job_id:) unless src_dir.directory?

    # Corrected files live under output/fixed/ and take priority over the same-named
    # files in output/. Pick a single source per file name (fixed winning, unmatched
    # output/ files kept), copy them into a flat directory, and import that so each
    # file is stored once under its own basename. Resolving before copying keeps a
    # read-only output/ file from being overwritten in place (which would fail).
    sources = {}

    [src_dir, src_dir.join('fixed')].each do |dir|
      next unless dir.directory?

      dir.each_child do |child|
        sources[child.basename.to_s] = child if child.file?
      end
    end

    Dir.mktmpdir do |tmp|
      merged = Pathname.new(tmp)

      sources.each_value do |src|
        FileUtils.cp src, merged
      end

      unarchive_and_copy_files(merged, working_dir.join(job_id)) do |name|
        files.create!(name:, parsing: true, ggs_job_id: job_id)
      end
    end
  end

  def job_output_dir(job_id)
    template = Rails.application.config_for(:app).ggs_jobs_dir_template!
    path     = template.gsub('{job_id}', job_id)

    raise "malformed directory path: #{path}" unless path == File.expand_path(path)

    Pathname.new(path)
  end
end
