require 'rails_helper'

RSpec.describe ExtractMetadataJob, type: :job do
  def write_file(path, content)
    dir = Rails.application.config_for(:app).mass_dir_path_template!.gsub('{user}', 'alice')

    FileUtils.mkdir_p dir
    File.write File.join(dir, path), content
  end

  let(:extraction) {
    create(:mass_directory_extraction, **{
      user: build(:user, uid: 'alice')
    })
  }

  describe 'ann' do
    example 'ok' do
      write_file 'foo.ann', <<~ANN
        COMMON	SUBMITTER		contact	Alice Liddell
        			email	alice@example.com
        			institute	Wonderland Inc.
        	DATE		hold_date	20200102
      ANN

      ExtractMetadataJob.perform_now extraction

      expect(extraction.files.first).to have_attributes(
        parsing: false,

        parsed_data: {
          'contactPerson' => {
            'fullName'    => 'Alice Liddell',
            'email'       => 'alice@example.com',
            'affiliation' => 'Wonderland Inc.'
          },
          'holdDate' => '2020-01-02'
        },

        _errors: []
      )
    end

    example 'empty' do
      write_file 'foo.ann', ''

      ExtractMetadataJob.perform_now extraction

      expect(extraction.files.first).to have_attributes(
        parsing: false,
        parsed_data: nil,

        _errors: [
          {'id' => 'annotation-file-parser.missing-contact-person', 'value' => nil}
        ]
      )
    end

    example 'missing contact person' do
      write_file 'foo.ann', <<~ANN
        COMMON	DATE		hold_date	20231126
      ANN

      ExtractMetadataJob.perform_now extraction

      expect(extraction.files.first).to have_attributes(
        parsing: false,
        parsed_data: nil,

        _errors: [
          {'id' => 'annotation-file-parser.missing-contact-person', 'value' => nil}
        ]
      )
    end

    example 'invalid contact person' do
      write_file 'foo.ann', <<~ANN
        COMMON	SUBMITTER		contact	Alice Liddell
      ANN

      ExtractMetadataJob.perform_now extraction

      expect(extraction.files.first).to have_attributes(
        parsing: false,
        parsed_data: nil,

        _errors: [
          {'id' => 'annotation-file-parser.invalid-contact-person', 'value' => nil}
        ]
      )
    end

    example 'invalid email' do
      write_file 'foo.ann', <<~ANN
        COMMON	SUBMITTER		contact	Alice Liddell
        			email	foo
        			institute	Wonderland Inc.
        	DATE		hold_date	20200102
      ANN

      ExtractMetadataJob.perform_now extraction

      expect(extraction.files.first).to have_attributes(
        parsing: false,
        parsed_data: nil,

        _errors: [
          {'id' => 'annotation-file-parser.invalid-email-address', 'value' => 'foo'}
        ]
      )
    end

    example 'duplicate contact person information (contact)' do
      write_file 'foo.ann', <<~ANN
        COMMON	SUBMITTER		contact	Alice Liddell
        			contact	Alice Liddell
      ANN

      ExtractMetadataJob.perform_now extraction

      expect(extraction.files.first).to have_attributes(
        parsing: false,
        parsed_data: nil,

        _errors: [
          {'id' => 'annotation-file-parser.duplicate-contact-person-information', 'value' => nil}
        ]
      )
    end

    example 'duplicate contact person information (email)' do
      write_file 'foo.ann', <<~ANN
        COMMON	SUBMITTER		contact	Alice Liddell
        			email	alice@example.com
        			email	alice@example.com
      ANN

      ExtractMetadataJob.perform_now extraction

      expect(extraction.files.first).to have_attributes(
        parsing: false,
        parsed_data: nil,

        _errors: [
          {'id' => 'annotation-file-parser.duplicate-contact-person-information', 'value' => nil}
        ]
      )
    end

    example 'duplicate contact person information (institute)' do
      write_file 'foo.ann', <<~ANN
        COMMON	SUBMITTER		contact	Alice Liddell
        			institute	Wonderland Inc.
        			institute	Wonderland Inc.
      ANN

      ExtractMetadataJob.perform_now extraction

      expect(extraction.files.first).to have_attributes(
        parsing: false,
        parsed_data: nil,

        _errors: [
          {'id' => 'annotation-file-parser.duplicate-contact-person-information', 'value' => nil}
        ]
      )
    end

    example 'invalid hold_date' do
      write_file 'foo.ann', <<~ANN
        COMMON	DATE		hold_date	foo
      ANN

      ExtractMetadataJob.perform_now extraction

      expect(extraction.files.first).to have_attributes(
        parsing: false,
        parsed_data: nil,

        _errors: [
          {'id' => 'annotation-file-parser.invalid-hold-date', 'value' => 'foo'}
        ]
      )
    end
  end

  describe 'seq' do
    example 'ok' do
      write_file 'foo.fasta', <<~SEQ
        >CLN01
        ggacaggctgccgcaggagccaggccgggagcaggaagaggcttcgggggagccggagaa
        ctgggccagatgcgcttcgtgggcgaagcctgaggaaaaagagagtgaggcaggagaatc
        gcttgaaccccggaggcggaaccgcactccagcctgggcgacagagtgagactta
        //
        >CLN02
        ctcacacagatgcgcgcacaccagtggttgtaacagaagcctgaggtgcgctcgtggtca
        gaagagggcatgcgcttcagtcgtgggcgaagcctgaggaaaaaatagtcattcatataa
        atttgaacacacctgctgtggctgtaactctgagatgtgctaaataaaccctctt
        //
      SEQ

      ExtractMetadataJob.perform_now extraction

      expect(extraction.files.first).to have_attributes(
        parsing: false,

        parsed_data: {
          'entriesCount' => 2
        },

        _errors: []
      )
    end

    example 'empty' do
      write_file 'foo.fasta', ''

      ExtractMetadataJob.perform_now extraction

      expect(extraction.files.first).to have_attributes(
        parsing:     false,
        parsed_data: nil,

        _errors: [
          {'id' => 'sequence-file-parser.no-entries', 'value' => nil}
        ]
      )
    end
  end
end
