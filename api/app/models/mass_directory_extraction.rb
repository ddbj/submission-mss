using Module.new {
  refine Pathname do
    def match_ext?(exts)
      path = to_s

      exts.find { path.end_with?(".#{_1}") }
    end

    def escape
      Shellwords.escape(to_s)
    end
  end
}

class MassDirectoryExtraction < ApplicationRecord
  ARCHIVE_EXT = %w[zip tar tar.gz tgz taz tar.Z taZ tar.bz2 tz2 tbz2 tbz tar.lz tar.lzma tlz tar.lzo tar.xz tar.zst tzst]

  COMPRESS = {
    gz:   "gzip --decompress --force",
    Z:    "compress -d -f",
    bz2:  "bzip2 --decompress --force",
    lz:   "lzip --decompress --force",
    lzma: "lzma --decompress --force",
    lzo:  "lzop -d -f",
    xz:   "xz --decompress --force",
    zst:  "zstd -d -f"
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
    Pathname.new(ENV.fetch("EXTRACTION_WORKDIR")).join("mass-directory-extraction-#{id}")
  end

  private

  def user_mass_dir
    username = user.id_token.fetch(:preferred_username)

    ENV.fetch("MASS_DIR_PATH_TEMPLATE").gsub("{user}", username).tap { |path|
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
            system "unzip #{dir.join(src).escape} -d #{dest.escape}", exception: true
          else
            system "tar --extract --file=#{dir.join(src).escape} --directory=#{dest.escape}", exception: true
          end

          unarchive_and_copy_files tmp
        end
      elsif ext = src.match_ext?(COMPRESS_EXT)
        comp_ext = ext.split(".").last

        Dir.mktmpdir do |tmp|
          tmp  = Pathname.new(tmp)
          dest = tmp.join(src.dirname).tap(&:mkpath)

          FileUtils.cp dir.join(src), dest
          system "#{COMPRESS.fetch(comp_ext)} #{tmp.join(src).escape}", exception: true

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
