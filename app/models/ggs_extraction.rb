class GgsExtraction < ApplicationRecord
  include Extraction
  include ArchiveExtraction

  OWNER_FILE_MAX_BYTES = 256

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
    raise Extraction::Error.new(:invalid_job_id, job_id:) unless job_id.match?(UUID_FORMAT)

    src_dir = job_output_dir(job_id)

    raise Extraction::Error.new(:directory_not_found, job_id:) unless src_dir.directory?
    raise Extraction::Error.new(:not_owner, job_id:)           if require_owner && !owner_matches?(job_id)

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
        # Each job keeps its files to itself here, but a submission copies them
        # all into one directory, where one would overwrite the other. Name the
        # job the file clashes with: it is not in front of the submitter.
        if other = files.find_by(name:)
          raise Extraction::Error.new(:duplicate_file_name_across_jobs, file: name, job_id:, other_job_id: other.ggs_job_id)
        end

        files.create!(name:, parsing: true, ggs_job_id: job_id)
      end
    end
  end

  # The GGS portal leaves the uid of whoever ran the job in .ggs-owner, next to
  # output/ rather than in it, so it is never copied. A token carries no proof
  # that its holder ran the job, so an extraction made with one has to match it.
  # Jobs from before the portal, or run outside it, have no such file and pass
  # as they always have. Anything else that is not a plain small file naming
  # this user -- or that we cannot read -- counts as someone else's.
  def owner_matches?(job_id)
    path = job_output_dir(job_id).parent.join('.ggs-owner')
    stat = File.lstat(path)

    return false unless stat.file?
    return false if stat.size > OWNER_FILE_MAX_BYTES

    # Opened without following a link or waiting on a pipe, in case the file
    # was swapped since the look above.
    owner = File.open(path, File::RDONLY | File::NOFOLLOW | File::NONBLOCK) {|f|
      next unless f.stat.file?

      f.read(OWNER_FILE_MAX_BYTES + 1)
    }

    return false if owner.nil? || owner.bytesize > OWNER_FILE_MAX_BYTES

    owner = owner.force_encoding(Encoding::UTF_8)

    owner.valid_encoding? && owner.strip == user.uid
  rescue Errno::ENOENT
    true
  rescue SystemCallError, IOError
    false
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
