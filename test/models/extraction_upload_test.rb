require 'test_helper'

class ExtractionUploadTest < ActiveSupport::TestCase
  test 'from_params finds a fulfilled extraction of the submitter' do
    fulfilled_extractions.each do |upload_class, extraction|
      via = upload_class.from_params(user: users(:alice), extraction_id: extraction.id)

      assert_equal extraction, via.extraction
    end
  end

  test 'from_params turns down an extraction belonging to someone else' do
    bob = User.create!(uid: 'bob', email: 'bob@example.com')

    fulfilled_extractions.each do |upload_class, extraction|
      assert_raises ActiveRecord::RecordNotFound do
        upload_class.from_params(user: bob, extraction_id: extraction.id)
      end
    end
  end

  test 'from_params turns down an extraction that has nothing to give' do
    extraction = dfast_extractions(:alice_dfast_extraction)

    %w[pending rejected].each do |state|
      extraction.update!(state:)

      assert_raises ActiveRecord::RecordNotFound do
        DfastUpload.from_params(user: users(:alice), extraction_id: extraction.id)
      end
    end
  end

  test 'from_params turns down a request that names no extraction' do
    assert_raises Upload::Malformed do
      DfastUpload.from_params(user: users(:alice))
    end
  end

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

    # Nor aside, where the half of them that were copied would be moved into
    # place along with the next attempt's own.
    assert_empty Dir.glob('*', base: submission.root_dir.join('../.work'))
  end

  private

  # Each upload reaches its extraction through its own association, so all
  # three are worth asking.
  def fulfilled_extractions
    {
      DfastUpload         => dfast_extractions(:alice_dfast_extraction),
      GgsUpload           => ggs_extractions(:alice_ggs_extraction),
      MassDirectoryUpload => mass_directory_extractions(:alice_mass_directory_extraction)
    }.each_value {
      _1.update! state: 'fulfilled'
    }
  end
end
