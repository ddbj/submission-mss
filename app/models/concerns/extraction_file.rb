module ExtractionFile
  class ParseError < StandardError
    def initialize(severity:, id:, value: nil)
      @severity = severity
      @id       = id
      @value    = value
    end

    attr_reader :severity, :id, :value
  end

  CONTACT_PERSON_QUALIFIERS = %w[contact email institute]

  ANN_EXT  = %w[ann annt.tsv ann.txt]
  SEQ_EXT  = %w[fasta fsa seq.fa fa fna seq]
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

    each_ann_line do |line|
      entry, _feature, _location, qualifier, value = line.split("\t")

      next if entry.nil?

      # The same whitespace as the browser's parser strips, so that the two
      # agree on what is blank.
      value = value&.gsub(/\A[[:space:]\uFEFF]+|[[:space:]\uFEFF]+\z/, '').presence

      in_common = entry == 'COMMON' unless entry.empty?

      # Templates, and DFAST jobs run without metadata, leave the contact
      # person's qualifiers with no value. Such a line says no more than a
      # missing one would.
      next if !value && CONTACT_PERSON_QUALIFIERS.include?(qualifier)

      if in_common
        case qualifier
        when 'contact'
          raise ParseError.new(
            severity: :error,
            id:       'annotation-file-parser.duplicate-contact-person-information'
          ) if full_name

          full_name = value
        when 'email'
          raise ParseError.new(
            severity: :error,
            id:       'annotation-file-parser.invalid-email-address',
            value:
          ) unless value.match?(URI::MailTo::EMAIL_REGEXP)

          raise ParseError.new(
            severity: :error,
            id:       'annotation-file-parser.duplicate-contact-person-information'
          ) if email

          email = value
        when 'institute'
          raise ParseError.new(
            severity: :error,
            id:       'annotation-file-parser.duplicate-contact-person-information'
          ) if affiliation

          affiliation = value
        when 'hold_date'
          # A blank or impossible date is not taken for none: that would publish
          # the data as soon as it is accepted, which cannot be taken back.
          hold_date = parse_hold_date(value)

          raise ParseError.new(
            severity: :error,
            id:       'annotation-file-parser.invalid-hold-date',
            value:
          ) unless hold_date

          # Allowed, but most likely not meant: the data is published as soon
          # as it has been processed.
          warnings << {severity: :warning, id: 'annotation-file-parser.past-hold-date', value:} if hold_date < Date.current.iso8601
        else
          # do nothing
        end
      else
        if qualifier == 'locus_tag' && value&.match?(/\Alocus_/i)
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

  # The lines as the browser's parser reads them: as UTF-8 whatever the file
  # claims, past a UTF-8 byte order mark, with bytes that are not UTF-8 replaced
  # rather than fatal, and ended by CR alone as well as by LF or CRLF. (Letting
  # Ruby follow the mark would have it read a UTF-16 file in an encoding it then
  # refuses to split.)
  def each_ann_line(&)
    fullpath.each_line(encoding: 'UTF-8').with_index do |chunk, i|
      chunk = chunk.delete_prefix("\uFEFF") if i.zero?

      chunk.scrub.split(/\r\n|\r|\n/).each(&)
    end
  end

  # YYYYMMDD, of a day that exists, as YYYY-MM-DD.
  def parse_hold_date(value)
    return nil unless value&.match?(/\A\d{8}\z/)

    # Gregorian throughout, as the browser and the database count days.
    Date.strptime(value, '%Y%m%d', Date::GREGORIAN).iso8601
  rescue Date::Error
    nil
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
