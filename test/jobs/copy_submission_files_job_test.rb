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

  # The job reads the upload back from the database, so the blob it downloads
  # is not one this test holds: stand in for all of them. Attachment delegates
  # what it does not have to its blob, which is where download really lives.
  def stub_download(replacement)
    original = ActiveStorage::Blob.instance_method(:download)

    ActiveStorage::Blob.define_method(:download, &replacement)

    yield
  ensure
    ActiveStorage::Blob.define_method(:download, original)
  end

  test 'copies files to submissions dir' do
    CopySubmissionFilesJob.perform_now @upload

    dir = Rails.root.join('tmp/storage/submissions/NSUB000042/20220102-123456')

    assert_equal 'directory', dir.ftype
    assert_equal 'file',      dir.join('example.ann').ftype
  end

  test 'the blobs are let go once the files are in place' do
    CopySubmissionFilesJob.perform_now @upload

    # Active Storage is the waiting room, not the shelf. Nothing else comes for
    # these: a sweep only takes the blobs nothing is attached to.
    assert_not @upload.via.reload.files.attached?
    assert_predicate @upload.reload, :copied_at
  end

  test 'a copy that landed but never let its blobs go is put right by being asked again' do
    # What a crash between the move and the purge leaves behind, which is how
    # two uploads sat for five months: the files were handed over, and the
    # blobs they came in stayed attached where no sweep could reach them.
    @upload.files_dir.mkpath
    @upload.files_dir.join('example.ann').write "COMMON\tSUBMITTER\t\tcontact\tAlice Liddell\n"

    CopySubmissionFilesJob.perform_now @upload

    assert_not @upload.via.reload.files.attached?
    assert_predicate @upload.reload, :copied_at

    assert_equal "COMMON\tSUBMITTER\t\tcontact\tAlice Liddell\n", @upload.files_dir.join('example.ann').read
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

    # Written down here as much as for a direct upload: the staging both go
    # through is the one place that knows the files have landed.
    assert_predicate upload.reload, :copied_at
  end

  test 'when the files landed is not moved by asking again' do
    CopySubmissionFilesJob.perform_now @upload

    landed = @upload.reload.copied_at

    travel 1.day do
      CopySubmissionFilesJob.perform_now @upload
    end

    # It says when the submitter's files reached the submission, which is not
    # something a later run has anything new to say about.
    assert_equal landed, @upload.reload.copied_at
  end

  test 'a copy that broke down on the way is tried again' do
    extraction = dfast_extractions(:alice_dfast_extraction)

    extraction.working_dir.mkpath
    extraction.files.create!(name: 'example.ann', dfast_job_id: 'job-1', parsing: false)
    extraction.working_dir.join('example.ann').write "COMMON\tSUBMITTER\t\tcontact\tAlice Liddell\n"

    upload   = Upload.create!(submission: @submission, via: DfastUpload.new(extraction:), created_at: '2022-05-06 07:08:09')
    attempts = 0

    cp = ->(*args) {
      attempts += 1

      raise Errno::EIO if attempts == 1

      FileUtils.copy(*args)
    }

    # Until this has run the blobs are the only copy of what the submitter
    # sent, and nothing else comes for them: a disk that hiccups once must not
    # be the end of it.
    perform_enqueued_jobs do
      FileUtils.stub :cp, cp do
        CopySubmissionFilesJob.perform_later upload
      end
    end

    assert_equal 2, attempts
    assert_equal ['example.ann'], Dir.glob('*', base: upload.files_dir)
  end

  test 'a download the storage could not answer is tried again' do
    attempts = 0

    # What SeaweedFS answering while it restarts arrives as -- neither a
    # SystemCallError nor a networking error. Named here as well as in the job,
    # so that the job failing to load for want of the constant is a test
    # failure rather than every upload breaking.
    stub_download ->(&block) {
      attempts += 1

      raise Aws::S3::Errors::ServiceUnavailable.new(nil, 'try later') if attempts == 1

      block.call "COMMON\tSUBMITTER\t\tcontact\tAlice Liddell\n"
    } do
      perform_enqueued_jobs do
        CopySubmissionFilesJob.perform_later @upload
      end
    end

    assert_equal 2, attempts
    assert_equal ['example.ann'], Dir.glob('*', base: @upload.files_dir)
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
