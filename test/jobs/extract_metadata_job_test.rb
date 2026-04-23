require 'test_helper'

class ExtractMetadataJobTest < ActiveJob::TestCase
  def write_file(path, content)
    dir = Rails.application.config_for(:app).mass_dir_path_template!.gsub('{user}', 'alice')

    FileUtils.mkdir_p dir
    File.write File.join(dir, path), content
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
end
