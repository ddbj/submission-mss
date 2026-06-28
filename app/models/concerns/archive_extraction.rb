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
          tmp  = Pathname.new(tmp)
          dest = tmp.join(src.to_s.delete_suffix(".#{ext}")).tap(&:mkpath)

          if src.to_s.end_with?('.zip')
            system 'unzip', src_dir.join(src).to_s, '-d', dest.to_s, exception: true
          else
            system 'tar', '--extract', '--file', src_dir.join(src).to_s, '--directory', dest.to_s, exception: true
          end

          unarchive_and_copy_files tmp, dest_dir, &build
        end
      elsif ext = src.match_ext?(COMPRESS_EXT)
        comp_ext = ext.split('.').last

        Dir.mktmpdir do |tmp|
          tmp  = Pathname.new(tmp)
          dest = tmp.join(src.dirname).tap(&:mkpath)

          FileUtils.cp src_dir.join(src), dest
          system(*COMPRESS.fetch(comp_ext), tmp.join(src).to_s, exception: true)

          copy_file tmp, dest_dir, src.to_s.delete_suffix(".#{comp_ext}"), &build
        end
      end
    end
  end

  def copy_file(base, dest_dir, src, &build)
    name = normalize_path(src)
    dest = dest_dir.join(name)

    raise Extraction::Error.new(:duplicate_file_name, reason: "duplicate file name: #{name}") if dest.exist?

    FileUtils.cp base.join(src), dest

    build.call name
  end
end
