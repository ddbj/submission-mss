module UploadVia
  extend ActiveSupport::Concern

  ANN_EXTENSIONS  = %w[.ann .annt.tsv .ann.txt].freeze
  TRIM_QUALIFIERS = %w[contact email institute].freeze

  included do
    has_one :upload, as: :via, touch: true, dependent: :destroy

    delegate :submission, to: :upload
  end

  private

  # Gathers the files aside, finishes them there, and moves them into place in
  # one go, so that the directory is never seen half filled -- neither by the
  # curator it is handed to, nor by the submitter, who is told what the upload
  # holds from where it came from until it is there.
  #
  # That move is also what records the copy: a job asked to do it again finds
  # the directory and leaves it be. Without this a retry renamed onto a full
  # directory, which fails with ENOTEMPTY however often it is tried.
  def stage_files
    return if upload.files_dir.exist?

    # Named after the upload rather than the directory it is bound for, which
    # is settled while the upload is being made: this runs long afterwards, and
    # asks nothing of what it was settled to be.
    work = submission.root_dir.join("../.work/#{submission.mass_id}-#{upload.id}")
    work.mkpath

    begin
      yield work

      trim_annotation_fields! work

      upload.files_dir.dirname.mkpath
      work.rename upload.files_dir
    ensure
      # The move takes this with it, so anything left is from an attempt that
      # broke down. Clear it out: it would otherwise sit here for good, and the
      # next attempt would move whatever it holds along with its own files.
      work.rmtree if work.exist?
    end
  end

  def trim_annotation_fields!(dir)
    dir.glob '*' do |path|
      next unless ANN_EXTENSIONS.any? { path.to_s.end_with?(_1) }

      content   = path.binread
      in_common = false
      modified  = false

      trimmed = content.each_line.map {|line|
        cols = line.chomp("\r\n").chomp("\r").chomp("\n").split("\t", -1)
        entry, qualifier, value = cols.values_at(0, 3, 4)

        next line if entry.nil?

        in_common = entry == 'COMMON' unless entry.empty?

        if in_common && value && TRIM_QUALIFIERS.include?(qualifier)
          stripped = value.strip

          if stripped != value
            cols[4]  = stripped
            eol      = line[/\r\n|\r|\n\z/] || ''
            modified = true

            cols.join("\t") + eol
          else
            line
          end
        else
          line
        end
      }.join

      path.binwrite trimmed if modified
    end
  end
end
