class GgsExtraction < ApplicationRecord
  include Extraction
  include ArchiveExtraction

  validates :ggs_job_ids, presence: true

  def prepare_files
    ActiveRecord::Base.transaction do
      ggs_job_ids.uniq.each do |job_id|
        copy_job_files job_id
      end
    end
  end

  private

  def copy_job_files(job_id)
    raise Extraction::Error.new(:invalid_job_id, job_id:, reason: "invalid job ID: #{job_id}") unless job_id.match?(UUID_FORMAT)

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

      dir.children.sort.each do |child|
        sources[source_name(child)] = child if child.file?
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

  # The same file can be plain in output/ and compressed in output/fixed/, or
  # the other way round. Key both on the name the import would store, so the
  # two are recognised as one file instead of colliding once expanded.
  def source_name(path)
    name = path.basename.to_s
    comp = COMPRESS.keys.find { name.end_with?(".#{_1}") }

    comp ? name.delete_suffix(".#{comp}") : name
  end

  def job_output_dir(job_id)
    template = Rails.application.config_for(:app).ggs_jobs_dir_template!
    path     = template.gsub('{job_id}', job_id)

    raise "malformed directory path: #{path}" unless path == File.expand_path(path)

    Pathname.new(path)
  end
end
