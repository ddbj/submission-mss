module ExtractionFile
  class ParseError < StandardError
    def initialize(severity:, id:, value: nil)
      @severity = severity
      @id       = id
      @value    = value
    end

    attr_reader :severity, :id, :value
  end

  ANN_EXT  = %w[ann annt.tsv ann.txt]
  SEQ_EXT  = %w[fasta seq.fa fa fna seq]
  FILE_EXT = ANN_EXT + SEQ_EXT

  def fullpath = extraction.working_dir.join(name)
  def size     = fullpath.size

  def parse
    if ANN_EXT.any? { name.end_with?(".#{_1}") }
      parse_ann
    elsif SEQ_EXT.any? { name.end_with?(".#{_1}") }
      parse_seq
    else
      raise "unsupported file: #{name}"
    end
  end

  def file_type
    if ANN_EXT.any? { name.end_with?(".#{_1}") }
      'annotation'
    elsif SEQ_EXT.any? { name.end_with?(".#{_1}") }
      'sequence'
    end
  end

  def annotation? = file_type == 'annotation'
  def sequence?   = file_type == 'sequence'

  def basename
    ext = FILE_EXT.find { name.end_with?(".#{_1}") } || '*'

    File.basename(name, ".#{ext}")
  end

  private

  def parse_ann
    in_common   = false
    full_name   = nil
    email       = nil
    affiliation = nil
    hold_date   = nil
    warnings    = []

    fullpath.each_line chomp: true do |line|
      entry, _feature, _location, qualifier, value = line.split("\t")

      in_common = entry == 'COMMON' unless entry.empty?

      if in_common
        case qualifier
        when 'contact'
          raise ParseError.new(
            severity: :error,
            id:       'annotation-file-parser.duplicate-contact-person-information'
          ) if full_name

          full_name = value&.strip
        when 'email'
          trimmed_email = value&.strip

          raise ParseError.new(
            severity: :error,
            id:       'annotation-file-parser.invalid-email-address',
            value:
          ) unless trimmed_email&.match?(URI::MailTo::EMAIL_REGEXP)

          raise ParseError.new(
            severity: :error,
            id:       'annotation-file-parser.duplicate-contact-person-information'
          ) if email

          email = trimmed_email
        when 'institute'
          raise ParseError.new(
            severity: :error,
            id:       'annotation-file-parser.duplicate-contact-person-information'
          ) if affiliation

          affiliation = value&.strip
        when 'hold_date'
          begin
            hold_date = Date.strptime(value, '%Y%m%d').strftime('%Y-%m-%d')
          rescue Date::Error
            raise ParseError.new(
              severity: :error,
              id:       'annotation-file-parser.invalid-hold-date',
              value:
            )
          end
        else
          # do nothing
        end
      else
        if qualifier == 'locus_tag' && value&.start_with?('locus_', 'LOCUS_')
          warnings << {severity: :warning, id: 'annotation-file-parser.temporary-locus-tag', value:}
        end
      end
    end

    raise ParseError.new(
      severity: :error,
      id:       'annotation-file-parser.missing-contact-person'
    ) if !full_name && !email && !affiliation

    raise ParseError.new(
      severity: :error,
      id:       'annotation-file-parser.invalid-contact-person'
    ) if !full_name || !email || !affiliation

    data = {
      contactPerson: {
        fullName: full_name,
        email:,
        affiliation:
      },

      holdDate: hold_date
    }

    [warnings, data]
  end

  def parse_seq
    count = 0
    buf   = String.new(capacity: 1.megabyte)
    bol   = true

    fullpath.open 'rb' do |io|
      while io.readpartial(1.megabyte, buf)
        count += 1 if bol && buf.start_with?('>')
        count += buf.scan(/[\r\n]>/).count

        bol = buf.end_with?("\r", "\n")
      end
    rescue EOFError
      # done
    end

    raise ParseError.new(
      severity: :error,
      id:       'sequence-file-parser.no-entries'
    ) if count.zero?

    [[], {entriesCount: count}]
  end
end
