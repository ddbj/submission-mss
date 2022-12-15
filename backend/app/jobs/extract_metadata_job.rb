class ExtractMetadataJob < ApplicationJob
  def perform(extraction)
    extraction.prepare_files

    extraction.files.find_each do |file|
      file.update!(
        parsing:     false,
        parsed_data: parse(file),
        _errors:     []
      )
    end

    extraction.update! state: 'fulfilled'
  end

  private

  def parse(file)
    case File.extname(file.name)
    when '.ann'
      parse_ann(file)
    when '.fasta'
      parse_fasta(file)
    else
      raise file.name
    end
  end

  def parse_ann(file)
    in_common   = false
    full_name   = nil
    email       = nil
    affiliation = nil
    hold_date   = nil

    file.fullpath.each_line chomp: true do |line|
      break if full_name && email && affiliation && hold_date

      entry, _feature, _location, qualifier, value = line.split("\t")

      break if in_common && entry.present?

      in_common = entry == 'COMMON' if entry.present?

      next unless in_common

      case qualifier
      when 'contact'
        full_name = value
      when 'email'
        email = value
      when 'institute'
        affiliation = value
      when 'hold_date'
        hold_date = Date.strptime(value, '%Y%m%d').strftime('%Y-%m-%d')
      else
        # do nothing
      end
    end

    {
      contactPerson: {
        fullName: full_name,
        email:,
        affiliation:
      },

      holdDate: hold_date
    }
  end

  def parse_fasta(file)
    count = 0
    buf   = String.new(capacity: 1.megabyte)
    bol   = true

    file.fullpath.open 'rb' do |io|
      while io.readpartial(1.megabyte, buf)
        count += 1 if bol && buf.start_with?('>')
        count += buf.scan(/[\r\n]>/).count

        bol = buf.end_with?("\r", "\n")
      end
    rescue EOFError
      # done
    end

    {
      entriesCount: count
    }
  end
end
