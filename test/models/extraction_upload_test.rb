require 'test_helper'

class ExtractionUploadTest < ActiveSupport::TestCase
  test 'a copy that fails partway leaves nothing behind' do
    submission = submissions(:alice_submission)
    extraction = dfast_extractions(:alice_dfast_extraction)

    extraction.working_dir.mkpath

    %w[test.ann test.fasta].each do |name|
      extraction.files.create!(name:, dfast_job_id: 'job-1', parsing: false)

      FileUtils.touch extraction.working_dir.join(name)
    end

    upload = submission.uploads.create!(via: DfastUpload.new(extraction:))
    copied = 0

    cp = ->(src, dest) {
      copied += 1

      raise 'the copy broke down' if copied > 1

      FileUtils.copy(src, dest)
    }

    FileUtils.stub :cp, cp do
      assert_raises(RuntimeError) { upload.via.copy_files_to_submissions_dir }
    end

    # The submission is told what the upload holds from the extraction until the
    # files are there. A directory holding some of them would be reported as all
    # there is, and the list the submitter sees would shrink.
    assert_empty Dir.glob('*', base: upload.files_dir)
  end
end
