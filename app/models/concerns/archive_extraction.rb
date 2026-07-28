require 'open3'

module ArchiveExtraction
  extend ActiveSupport::Concern

  using Module.new {
    refine Pathname do
      def match_ext?(exts)
        path = to_s

        exts.find { path.end_with?(".#{_1}") }
      end
    end
  }

  ARCHIVE_EXT = %w[zip tar tar.gz tgz taz tar.Z taZ tar.bz2 tz2 tbz2 tbz tar.lz tar.lzma tlz tar.lzo tar.xz tar.zst tzst]

  COMPRESS = {
    gz:   %w[gzip --decompress --force],
    Z:    %w[compress -d -f],
    bz2:  %w[bzip2 --decompress --force],
    lz:   %w[lzip --decompress --force],
    lzma: %w[lzma --decompress --force],
    lzo:  %w[lzop -d -f],
    xz:   %w[xz --decompress --force],
    zst:  %w[zstd -d -f]
  }.stringify_keys

  COMPRESS_EXT = ExtractionFile::FILE_EXT.product(COMPRESS.keys).map { "#{_1}.#{_2}" }

  private

  # Recursively scan +src_dir+ for submission files (the same set the SFTP
  # import accepts), unarchiving and decompressing as needed, and copy each one
  # into +dest_dir+. The block is called with the stored file name so callers
  # can create the record with any extra attributes they need.
  def unarchive_and_copy_files(src_dir, dest_dir, &build)
    paths = Pathname.glob("**/*.{#{[*ExtractionFile::FILE_EXT, *ARCHIVE_EXT, *COMPRESS_EXT].join(',')}}", base: src_dir)

    return if paths.empty?

    dest_dir.mkpath

    paths.each do |src|
      if src.match_ext?(ExtractionFile::FILE_EXT)
        copy_file src_dir, dest_dir, src, &build
      elsif ext = src.match_ext?(ARCHIVE_EXT)
        Dir.mktmpdir do |tmp|
          tmp   = Pathname.new(tmp)
          input = src_dir.join(src)
          dest  = tmp.join(src.to_s.delete_suffix(".#{ext}")).tap(&:mkpath)

          if src.to_s.end_with?('.zip')
            extract! src, input, 'unzip', input.to_s, '-d', dest.to_s
          else
            extract! src, input, 'tar', '--extract', '--file', input.to_s, '--directory', dest.to_s
          end

          unarchive_and_copy_files tmp, dest_dir, &build
        end
      elsif ext = src.match_ext?(COMPRESS_EXT)
        comp_ext = ext.split('.').last

        Dir.mktmpdir do |tmp|
          tmp   = Pathname.new(tmp)
          input = tmp.join(src)
          dest  = tmp.join(src.dirname).tap(&:mkpath)

          FileUtils.cp src_dir.join(src), dest
          extract! src, input, *COMPRESS.fetch(comp_ext), input.to_s

          copy_file tmp, dest_dir, src.to_s.delete_suffix(".#{comp_ext}"), &build
        end
      end
    end
  end

  # Run an archive/decompression command on a user-supplied file. A broken or
  # unsupported input makes the command exit non-zero; surface that as an
  # Extraction::Error so the job rejects the extraction and shows the reason to
  # the user, instead of crashing with an opaque error. A genuinely missing
  # binary still raises Errno::ENOENT so it reaches Sentry as a deployment bug.
  def extract!(name, input, *command)
    _out, err, status = Open3.capture3(*command)

    return if status.success?

    # Report the first meaningful line, rewriting the internal temp/mass-dir
    # path to the file's own name so we never leak server paths to the user.
    detail = err.gsub(input.to_s, name.to_s).each_line.map(&:strip).find(&:present?)
    detail ||= "#{command.first} exited with status #{status.exitstatus}"

    raise Extraction::Error.new(:invalid_archive, reason: "#{name}: #{detail}")
  end

  def copy_file(base, dest_dir, src, &build)
    name = normalize_path(src)
    dest = dest_dir.join(name)

    raise Extraction::Error.new(:duplicate_file_name, reason: "duplicate file name: #{name}") if dest.exist?

    FileUtils.cp base.join(src), dest

    build.call name
  end
end
