module UploadVia
  extend ActiveSupport::Concern

  ANN_EXTENSIONS  = %w[.ann .annt.tsv .ann.txt].freeze
  TRIM_QUALIFIERS = %w[contact email institute].freeze

  included do
    has_one :upload, as: :via, touch: true, dependent: :destroy
  end

  private

  def trim_annotation_fields!
    upload.files_dir.glob '*' do |path|
      next unless ANN_EXTENSIONS.any? { path.to_s.end_with?(_1) }

      content   = path.binread
      in_common = false
      modified  = false

      trimmed = content.each_line.map {|line|
        cols = line.chomp("\r\n").chomp("\r").chomp("\n").split("\t", -1)
        entry, qualifier, value = cols.values_at(0, 3, 4)

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
