require 'test_helper'

class PurgeExtractionsJobTest < ActiveJob::TestCase
  def extraction_with_files(created_at:)
    extraction = DfastExtraction.create!(user: users(:alice), dfast_job_ids: ['job-1'], state: 'fulfilled', created_at:)

    extraction.working_dir.mkpath
    extraction.working_dir.join('test.ann').write "COMMON\tSUBMITTER\t\tcontact\tAlice Liddell\n"
    extraction.files.create!(name: 'test.ann', dfast_job_id: 'job-1', parsing: false)

    extraction
  end

  test 'gathered files are let go once nobody is coming back for them' do
    old = extraction_with_files(created_at: (PurgeExtractionsJob::RETENTION + 1.day).ago)

    PurgeExtractionsJob.perform_now

    assert_not old.working_dir.exist?

    # The records go with the directory: a file left pointing at nothing would
    # be asked for its size the next time the extraction is rendered.
    assert_empty old.files.reload
  end

  test 'a directory left behind with no records to name it' do
    # A directory is made outside the transaction the records are made in, so a
    # failure that is not an Extraction::Error rolls the records back and leaves
    # the directory -- the case most worth sweeping, and the one a query that
    # starts from the records cannot see.
    stranded = DfastExtraction.create!(
      user:           users(:alice),
      dfast_job_ids:  ['job-1'],
      created_at:     (PurgeExtractionsJob::RETENTION + 1.day).ago
    )

    stranded.working_dir.mkpath

    PurgeExtractionsJob.perform_now

    assert_not stranded.working_dir.exist?
  end

  test 'an extraction still in reach is left alone' do
    recent = extraction_with_files(created_at: (PurgeExtractionsJob::RETENTION - 1.day).ago)

    PurgeExtractionsJob.perform_now

    assert recent.working_dir.join('test.ann').exist?
    assert_equal 1, recent.files.reload.count
  end

  test 'the extraction itself stays, because an upload made from it reads it' do
    extraction = extraction_with_files(created_at: (PurgeExtractionsJob::RETENTION + 1.day).ago)
    upload     = submissions(:alice_submission).uploads.create!(via: DfastUpload.new(extraction:))

    PurgeExtractionsJob.perform_now

    assert_equal ['job-1'], upload.via.reload.job_ids
  end
end
