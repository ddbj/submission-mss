using Module.new {
  refine Pathname do
    def match_ext?(exts)
      path = to_s

      exts.find { path.end_with?(".#{_1}") }
    end
  end
}

class MassDirectoryExtraction < ApplicationRecord
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

  belongs_to :user

  has_many :files, dependent: :destroy, class_name: "MassDirectoryExtractionFile", foreign_key: :extraction_id

  def prepare_files
    ActiveRecord::Base.transaction do
      unarchive_and_copy_files user_mass_dir
    end
  end

  def working_dir
    base = Rails.env.test? ? "tmp/storage" : "storage"

    Rails.root.join(base, "extracts/mass-directory-#{id}")
  end

  private

  def user_mass_dir
    Rails.application.config_for(:app).mass_dir_path_template!.gsub("{user}", user.uid).tap { |path|
      raise "malformed directory path: #{path}" unless path == File.expand_path(path)
    }.then { Pathname.new(_1) }
  end

  def unarchive_and_copy_files(dir)
    paths = Pathname.glob("**/*.{#{[ *ExtractionFile::FILE_EXT, *ARCHIVE_EXT, *COMPRESS_EXT ].join(',')}}", base: dir)

    return if paths.empty?

    working_dir.mkpath

    paths.each do |src|
      if src.match_ext?(ExtractionFile::FILE_EXT)
        copy_file dir, src
      elsif ext = src.match_ext?(ARCHIVE_EXT)
        Dir.mktmpdir do |tmp|
          tmp  = Pathname.new(tmp)
          dest = tmp.join(src.to_s.delete_suffix(".#{ext}")).tap(&:mkpath)

          if src.to_s.end_with?(".zip")
            system "unzip", dir.join(src).to_s, "-d", dest.to_s, exception: true
          else
            system "tar", "--extract", "--file", dir.join(src).to_s, "--directory", dest.to_s, exception: true
          end

          unarchive_and_copy_files tmp
        end
      elsif ext = src.match_ext?(COMPRESS_EXT)
        comp_ext = ext.split(".").last

        Dir.mktmpdir do |tmp|
          tmp  = Pathname.new(tmp)
          dest = tmp.join(src.dirname).tap(&:mkpath)

          FileUtils.cp dir.join(src), dest
          system(*COMPRESS.fetch(comp_ext), tmp.join(src).to_s, exception: true)

          copy_file tmp, src.to_s.delete_suffix(".#{comp_ext}")
        end
      end
    end
  end

  def copy_file(base, src)
    dest = normalize_path(src)

    FileUtils.cp base.join(src), working_dir.join(dest)

    files.create!(
      name:    dest,
      parsing: true
    )
  end

  def normalize_path(path)
    path.to_s.gsub(%r{[/ ]}, "/" => "__", " " => "_")
  end
end
