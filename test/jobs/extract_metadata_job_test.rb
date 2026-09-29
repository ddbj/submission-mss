require 'test_helper'

class ExtractMetadataJobTest < ActiveJob::TestCase
  def write_file(path, content)
    dir = Rails.application.config_for(:app).mass_dir_path_template!.gsub('{user}', 'alice')

    FileUtils.mkdir_p dir
    File.binwrite File.join(dir, path), content
  end

  setup do
    @extraction = MassDirectoryExtraction.create!(user: users(:alice))
  end

  test 'ann: ok' do
    write_file 'foo.ann', <<~ANN
      COMMON\tSUBMITTER\t\tcontact\tAlice Liddell
      \t\t\temail\talice@example.com
      \t\t\tinstitute\tWonderland Inc.
      \tDATE\t\thold_date\t20200102
    ANN

    ExtractMetadataJob.perform_now @extraction

    file = @extraction.files.first

    assert_equal false, file.parsing

    assert_equal({
      'contactPerson' => {
        'fullName'    => 'Alice Liddell',
        'email'       => 'alice@example.com',
        'affiliation' => 'Wonderland Inc.'
      },
      'holdDate' => '2020-01-02'
    }, file.parsed_data)

    assert_equal [], file._errors
  end

  test 'ann: empty' do
    write_file 'foo.ann', ''

    ExtractMetadataJob.perform_now @extraction

    file = @extraction.files.first

    assert_equal false, file.parsing
    assert_nil file.parsed_data

    assert_equal [
      'severity' => 'error',
      'id'       => 'annotation-file-parser.missing-contact-person',
      'value'    => nil
    ], file._errors
  end

  test 'ann: missing contact person' do
    write_file 'foo.ann', <<~ANN
      COMMON\tDATE\t\thold_date\t20231126
    ANN

    ExtractMetadataJob.perform_now @extraction

    file = @extraction.files.first

    assert_equal false, file.parsing
    assert_nil file.parsed_data

    assert_equal [
      'severity' => 'error',
      'id'       => 'annotation-file-parser.missing-contact-person',
      'value'    => nil
    ], file._errors
  end

  test 'ann: invalid contact person' do
    write_file 'foo.ann', <<~ANN
      COMMON\tSUBMITTER\t\tcontact\tAlice Liddell
    ANN

    ExtractMetadataJob.perform_now @extraction

    file = @extraction.files.first

    assert_equal false, file.parsing
    assert_nil file.parsed_data

    assert_equal [
      'severity' => 'error',
      'id'       => 'annotation-file-parser.invalid-contact-person',
      'value'    => nil
    ], file._errors
  end

  test 'ann: invalid email' do
    write_file 'foo.ann', <<~ANN
      COMMON\tSUBMITTER\t\tcontact\tAlice Liddell
      \t\t\temail\tfoo
      \t\t\tinstitute\tWonderland Inc.
      \tDATE\t\thold_date\t20200102
    ANN

    ExtractMetadataJob.perform_now @extraction

    file = @extraction.files.first

    assert_equal false, file.parsing
    assert_nil file.parsed_data

    assert_equal [
      'severity' => 'error',
      'id'       => 'annotation-file-parser.invalid-email-address',
      'value'    => 'foo'
    ], file._errors
  end

  test 'ann: duplicate contact person information (contact)' do
    write_file 'foo.ann', <<~ANN
      COMMON\tSUBMITTER\t\tcontact\tAlice Liddell
      \t\t\tcontact\tAlice Liddell
    ANN

    ExtractMetadataJob.perform_now @extraction

    file = @extraction.files.first

    assert_equal false, file.parsing
    assert_nil file.parsed_data

    assert_equal [
      'severity' => 'error',
      'id'       => 'annotation-file-parser.duplicate-contact-person-information',
      'value'    => nil
    ], file._errors
  end

  test 'ann: duplicate contact person information (email)' do
    write_file 'foo.ann', <<~ANN
      COMMON\tSUBMITTER\t\tcontact\tAlice Liddell
      \t\t\temail\talice@example.com
      \t\t\temail\talice@example.com
    ANN

    ExtractMetadataJob.perform_now @extraction

    file = @extraction.files.first

    assert_equal false, file.parsing
    assert_nil file.parsed_data

    assert_equal [
      'severity' => 'error',
      'id'       => 'annotation-file-parser.duplicate-contact-person-information',
      'value'    => nil
    ], file._errors
  end

  test 'ann: duplicate contact person information (institute)' do
    write_file 'foo.ann', <<~ANN
      COMMON\tSUBMITTER\t\tcontact\tAlice Liddell
      \t\t\tinstitute\tWonderland Inc.
      \t\t\tinstitute\tWonderland Inc.
    ANN

    ExtractMetadataJob.perform_now @extraction

    file = @extraction.files.first

    assert_equal false, file.parsing
    assert_nil file.parsed_data

    assert_equal [
      'severity' => 'error',
      'id'       => 'annotation-file-parser.duplicate-contact-person-information',
      'value'    => nil
    ], file._errors
  end

  test 'ann: invalid hold_date' do
    write_file 'foo.ann', <<~ANN
      COMMON\tDATE\t\thold_date\tfoo
    ANN

    ExtractMetadataJob.perform_now @extraction

    file = @extraction.files.first

    assert_equal false, file.parsing
    assert_nil file.parsed_data

    assert_equal [
      'severity' => 'error',
      'id'       => 'annotation-file-parser.invalid-hold-date',
      'value'    => 'foo'
    ], file._errors
  end

  # What DFAST leaves in the file when it is run without its metadata: the
  # qualifiers are there, their values are not.
  test 'ann: blank contact person' do
    write_file 'foo.ann', <<~ANN
      COMMON\tSUBMITTER\t\tcontact\t
      \t\t\temail\t
      \t\t\tinstitute
    ANN

    ExtractMetadataJob.perform_now @extraction

    file = @extraction.files.first

    assert_equal false, file.parsing
    assert_nil file.parsed_data

    assert_equal [
      'severity' => 'error',
      'id'       => 'annotation-file-parser.missing-contact-person',
      'value'    => nil
    ], file._errors
  end

  test 'ann: blank contact name' do
    write_file 'foo.ann', <<~ANN
      COMMON\tSUBMITTER\t\tcontact\t\u3000
      \t\t\temail\talice@example.com
      \t\t\tinstitute\tWonderland Inc.
    ANN

    ExtractMetadataJob.perform_now @extraction

    file = @extraction.files.first

    assert_equal false, file.parsing
    assert_nil file.parsed_data

    assert_equal [
      'severity' => 'error',
      'id'       => 'annotation-file-parser.invalid-contact-person',
      'value'    => nil
    ], file._errors
  end

  test 'ann: blank email address' do
    write_file 'foo.ann', <<~ANN
      COMMON\tSUBMITTER\t\tcontact\tAlice Liddell
      \t\t\temail\t\s
      \t\t\tinstitute\tWonderland Inc.
    ANN

    ExtractMetadataJob.perform_now @extraction

    file = @extraction.files.first

    assert_equal false, file.parsing
    assert_nil file.parsed_data

    assert_equal [
      'severity' => 'error',
      'id'       => 'annotation-file-parser.invalid-contact-person',
      'value'    => nil
    ], file._errors
  end

  test 'ann: a blank line is not a second contact person' do
    write_file 'foo.ann', <<~ANN
      COMMON\tSUBMITTER\t\tcontact\tAlice Liddell
      \t\t\tcontact\t
      \t\t\temail\talice@example.com
      \t\t\tinstitute\tWonderland Inc.
    ANN

    ExtractMetadataJob.perform_now @extraction

    file = @extraction.files.first

    assert_equal [], file._errors
    assert_equal 'Alice Liddell', file.parsed_data.dig('contactPerson', 'fullName')
  end

  ["hold_date\t", 'hold_date', "hold_date\t  ", "hold_date\t20250229", "hold_date\t20251301", "hold_date\t202501011", "hold_date\t15000229"].each do |line|
    test "ann: blank or impossible hold_date (#{line.inspect})" do
      write_file 'foo.ann', "COMMON\tDATE\t\t#{line}\n"

      ExtractMetadataJob.perform_now @extraction

      file = @extraction.files.first

      assert_equal false, file.parsing
      assert_nil file.parsed_data

      assert_equal [
        'severity' => 'error',
        'id'       => 'annotation-file-parser.invalid-hold-date',
        'value'    => line.split("\t")[1]&.strip.presence
      ], file._errors
    end
  end

  # The day before the Gregorian reform, which only a Julian calendar skips.
  test 'ann: a hold date counted in the Gregorian calendar' do
    write_file 'foo.ann', <<~ANN
      COMMON\tSUBMITTER\t\tcontact\tAlice Liddell
      \t\t\temail\talice@example.com
      \t\t\tinstitute\tWonderland Inc.
      \tDATE\t\thold_date\t15821010
    ANN

    ExtractMetadataJob.perform_now @extraction

    assert_equal '1582-10-10', @extraction.files.first.parsed_data['holdDate']
  end

  # The browser reads it as UTF-8 too, and finds no contact person in it.
  test 'ann: UTF-16' do
    write_file 'foo.ann', "\uFEFFCOMMON\tSUBMITTER\t\tcontact\tAlice Liddell\n".encode('UTF-16LE').b

    ExtractMetadataJob.perform_now @extraction

    file = @extraction.files.first

    assert_equal 'fulfilled', @extraction.reload.state

    assert_equal [
      'severity' => 'error',
      'id'       => 'annotation-file-parser.missing-contact-person',
      'value'    => nil
    ], file._errors
  end

  {
    'a byte order mark'            => "\uFEFFCOMMON\tSUBMITTER\t\tcontact\tAlice Liddell\n\t\t\temail\talice@example.com\n\t\t\tinstitute\tWonderland Inc.\n",
    'lines ended by CR'            => "COMMON\tSUBMITTER\t\tcontact\tAlice Liddell\r\t\t\temail\talice@example.com\r\t\t\tinstitute\tWonderland Inc.\r",
    'bytes that are not UTF-8'     => "COMMON\tSUBMITTER\t\tcontact\tAlice Liddell\n\t\t\temail\talice@example.com\n\t\t\tinstitute\tWonderland Inc.\nCLN01\tsource\t1..100\tnote\tcaf\xE9\n".b,
    'surrounding full-width space' => "COMMON\tSUBMITTER\t\tcontact\tAlice Liddell\u3000\n\t\t\temail\talice@example.com\u3000\n\t\t\tinstitute\tWonderland Inc.\n"
  }.each do |desc, content|
    test "ann: #{desc}" do
      write_file 'foo.ann', content

      ExtractMetadataJob.perform_now @extraction

      file = @extraction.files.first

      assert_equal [], file._errors

      assert_equal({
        'fullName'    => 'Alice Liddell',
        'email'       => 'alice@example.com',
        'affiliation' => 'Wonderland Inc.'
      }, file.parsed_data['contactPerson'])
    end
  end

  test 'ann: temporary locus_tag' do
    write_file 'foo.ann', <<~ANN
      COMMON\tSUBMITTER\t\tcontact\tAlice Liddell
      \t\t\temail\talice@example.com
      \t\t\tinstitute\tWonderland Inc.
      CLN01\tgene\t1..100\tlocus_tag\tlocus_0001
      \tgene\t101..200\tlocus_tag\tLOCUS_0002
      \tgene\t201..300\tlocus_tag\tLocus_0003
    ANN

    ExtractMetadataJob.perform_now @extraction

    file = @extraction.files.first

    assert_equal false, file.parsing

    assert_equal({
      'contactPerson' => {
        'fullName'    => 'Alice Liddell',
        'email'       => 'alice@example.com',
        'affiliation' => 'Wonderland Inc.'
      },
      'holdDate' => nil
    }, file.parsed_data)

    assert_equal [
      {'severity' => 'warning', 'id' => 'annotation-file-parser.temporary-locus-tag', 'value' => 'locus_0001'},
      {'severity' => 'warning', 'id' => 'annotation-file-parser.temporary-locus-tag', 'value' => 'LOCUS_0002'},
      {'severity' => 'warning', 'id' => 'annotation-file-parser.temporary-locus-tag', 'value' => 'Locus_0003'}
    ], file._errors
  end

  test 'seq: ok' do
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

    ExtractMetadataJob.perform_now @extraction

    file = @extraction.files.first

    assert_equal false, file.parsing
    assert_equal({'entriesCount' => 2}, file.parsed_data)
    assert_equal [], file._errors
  end

  test 'seq: empty' do
    write_file 'foo.fasta', ''

    ExtractMetadataJob.perform_now @extraction

    file = @extraction.files.first

    assert_equal false, file.parsing
    assert_nil file.parsed_data

    assert_equal [
      'severity' => 'error',
      'id'       => 'sequence-file-parser.no-entries',
      'value'    => nil
    ], file._errors
  end

  test 'archive: broken' do
    write_file 'aaa.ann', <<~ANN
      COMMON\tSUBMITTER\t\tcontact\tAlice Liddell
      \t\t\temail\talice@example.com
      \t\t\tinstitute\tWonderland Inc.
    ANN

    write_file 'zzz.tar', 'this is not a tar archive'

    ExtractMetadataJob.perform_now @extraction

    @extraction.reload

    assert_equal 'rejected', @extraction.state
    assert_equal 'invalid_archive', @extraction.error['id']
    assert_match(/\Azzz\.tar: /, @extraction.error['reason'])

    # aaa.ann is copied before zzz.tar fails; the rejection must keep no files,
    # on disk no more than in the database.
    assert_empty @extraction.files
    assert_not @extraction.working_dir.exist?
  end

  test 'archive: unreadable file (broken symlink)' do
    write_file 'aaa.ann', <<~ANN
      COMMON\tSUBMITTER\t\tcontact\tAlice Liddell
      \t\t\temail\talice@example.com
      \t\t\tinstitute\tWonderland Inc.
    ANN

    dir = Rails.application.config_for(:app).mass_dir_path_template!.gsub('{user}', 'alice')
    File.symlink '/nonexistent/target.ann', File.join(dir, 'zzz.ann')

    ExtractMetadataJob.perform_now @extraction

    @extraction.reload

    assert_equal 'rejected', @extraction.state
    assert_equal 'unreadable_file', @extraction.error['id']
    assert_equal 'zzz.ann: broken symlink', @extraction.error['reason']

    # aaa.ann is copied before zzz.ann fails; the rejection must keep no files.
    assert_empty @extraction.files
  end

  test 'an unexpected failure rejects the extraction' do
    write_file 'foo.fasta', ">entry1\nATCG\n"

    def @extraction.prepare_files
      super

      raise 'something we did not see coming'
    end

    assert_raises RuntimeError do
      ExtractMetadataJob.perform_now @extraction
    end

    @extraction.reload

    assert_equal 'rejected', @extraction.state
    assert_equal 'unexpected', @extraction.error['id']
    assert_empty @extraction.files, 'what was gathered before the failure goes'
    assert_not @extraction.working_dir.exist?
  end

  test 'an extraction no longer pending is left alone' do
    @extraction.update! state: 'rejected', error: {id: 'unexpected'}

    write_file 'foo.fasta', ">entry1\nATCG\n"

    ExtractMetadataJob.perform_now @extraction

    assert_equal 'rejected', @extraction.reload.state
    assert_empty @extraction.files
  end
end
