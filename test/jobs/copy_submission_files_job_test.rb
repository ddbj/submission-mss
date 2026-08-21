require 'test_helper'

using TmpUploadedFile

class CopySubmissionFilesJobTest < ActiveJob::TestCase
  setup do
    @submission = Submission.create!(
      mass_id:        'NSUB000042',
      user:           users(:alice),
      tpa:            false,
      entries_count:  1,
      sequencer:      'ngs',
      data_type:      'wgs',
      description:    'some description',
      email_language: 'en',

      contact_person: ContactPerson.new(
        email:       'alice+contact@example.com',
        full_name:   'Alice Liddell',
        affiliation: 'Wonderland Inc.'
      )
    )

    via = WebuiUpload.create!(files: [
      Rack::Test::UploadedFile.tmp('example.ann')
    ])

    @upload = Upload.create!(
      submission: @submission,
      via:,
      created_at: '2022-01-02 12:34:56'
    )
  end

  test 'copies files to submissions dir' do
    CopySubmissionFilesJob.perform_now @upload

    dir = Rails.root.join('tmp/storage/submissions/NSUB000042/20220102-123456')

    assert_equal 'directory', dir.ftype
    assert_equal 'file',      dir.join('example.ann').ftype
  end

  test 'running again over files already in place' do
    extraction = dfast_extractions(:alice_dfast_extraction)

    extraction.working_dir.mkpath
    extraction.files.create!(name: 'example.ann', dfast_job_id: 'job-1', parsing: false)

    extraction.working_dir.join('example.ann').write "COMMON\tSUBMITTER\t\tcontact\tAlice Liddell\n"

    upload = Upload.create!(submission: @submission, via: DfastUpload.new(extraction:), created_at: '2022-03-04 01:02:03')

    2.times do
      CopySubmissionFilesJob.perform_now upload
    end

    assert_equal ['example.ann'], Dir.glob('*', base: upload.files_dir)
  end

  test 'trim whitespace from contact fields in annotation files' do
    ann_content = <<~TSV
      COMMON\tSUBMITTER\t\tcontact\t Alice Liddell
      \t\t\temail\t alice@example.com
      \t\t\tinstitute\t Wonderland Inc.
      ENTRY\ttest
    TSV

    submission = Submission.create!(
      mass_id:        'NSUB000099',
      user:           users(:alice),
      tpa:            false,
      entries_count:  1,
      sequencer:      'ngs',
      data_type:      'wgs',
      email_language: 'en',
      created_at:     '2022-01-01',

      contact_person: ContactPerson.new(
        email:       'alice+contact@example.com',
        full_name:   'Alice Liddell',
        affiliation: 'Wonderland Inc.'
      )
    )

    via = WebuiUpload.create!(files: [
      Rack::Test::UploadedFile.tmp('example.ann', content: ann_content),
      Rack::Test::UploadedFile.tmp('example.fasta')
    ])

    upload = Upload.create!(
      submission:,
      via:,
      created_at: '2022-01-02 12:34:56'
    )

    CopySubmissionFilesJob.perform_now upload

    result = Rails.root.join('tmp/storage/submissions/NSUB000099/20220102-123456/example.ann').read

    assert_equal <<~TSV, result
      COMMON\tSUBMITTER\t\tcontact\tAlice Liddell
      \t\t\temail\talice@example.com
      \t\t\tinstitute\tWonderland Inc.
      ENTRY\ttest
    TSV
  end
end
