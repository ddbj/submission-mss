require 'test_helper'

class ReportUncopiedUploadsJobTest < ActiveJob::TestCase
  setup do
    @submission = submissions(:alice_submission)

    # The fixture upload is one of these too, so put its files in place and
    # leave each test to introduce the one it is about.
    uploads(:alice_upload).files_dir.mkpath
  end

  def webui_upload(created_at:, arrived: true, copied: true)
    @submission.uploads.create!(via: WebuiUpload.new(copied:), created_at:).tap {
      _1.files_dir.mkpath if arrived
    }
  end

  def extraction_upload(created_at:, arrived: true)
    extraction = dfast_extractions(:alice_dfast_extraction)

    @submission.uploads.create!(via: DfastUpload.new(extraction:), created_at:).tap {
      _1.files_dir.mkpath if arrived
    }
  end

  def reports(klass, &)
    capture_error_reports(klass, &).map { _1.error.message }
  end

  test 'an upload whose files never arrived is reported' do
    stuck = webui_upload(created_at: 2.days.ago, arrived: false)

    # It sat like this for two years and ten months once, and nothing said so.
    assert_equal ["the files of upload #{@submission.mass_id}/#{stuck.files_dir_name} never reached the submission"],
                 reports(ReportUncopiedUploadsJob::UncopiedUpload) { ReportUncopiedUploadsJob.perform_now }
  end

  test 'an upload that came from an extraction is asked after the same way' do
    stuck = extraction_upload(created_at: 2.days.ago, arrived: false)

    assert_equal ["the files of upload #{@submission.mass_id}/#{stuck.files_dir_name} never reached the submission"],
                 reports(ReportUncopiedUploadsJob::UncopiedUpload) { ReportUncopiedUploadsJob.perform_now }
  end

  test 'each one is named on its own, rather than gathered into a sentence' do
    first  = webui_upload(created_at: 2.days.ago, arrived: false)
    second = webui_upload(created_at: 3.days.ago, arrived: false)

    # One thing to answer for apiece: a sentence listing both would be a
    # different sentence the day one of them is dealt with.
    assert_equal 2, reports(ReportUncopiedUploadsJob::UncopiedUpload) { ReportUncopiedUploadsJob.perform_now }.size

    assert_equal [first, second].map { "the files of upload #{@submission.mass_id}/#{_1.files_dir_name} never reached the submission" }.sort,
                 reports(ReportUncopiedUploadsJob::UncopiedUpload) { ReportUncopiedUploadsJob.perform_now }.sort
  end

  test 'files that arrived without their blobs being let go' do
    upload = webui_upload(created_at: 2.days.ago, copied: false)

    # The waiting room is meant to empty as the files leave it. This one did
    # not, and no sweep reaches a blob that is still attached.
    assert_equal ["the files of upload #{@submission.mass_id}/#{upload.files_dir_name} arrived, but the blobs they came in were never let go"],
                 reports(ReportUncopiedUploadsJob::UnreleasedBlobs) { ReportUncopiedUploadsJob.perform_now }
  end

  test 'an upload whose files are in place is not reported' do
    webui_upload created_at: 2.days.ago

    assert_empty reports(ReportUncopiedUploadsJob::UncopiedUpload) { ReportUncopiedUploadsJob.perform_now }
    assert_empty reports(ReportUncopiedUploadsJob::UnreleasedBlobs) { ReportUncopiedUploadsJob.perform_now }
  end

  test 'an upload still on its way is given time to arrive' do
    webui_upload created_at: 1.hour.ago, arrived: false

    assert_empty reports(ReportUncopiedUploadsJob::UncopiedUpload) { ReportUncopiedUploadsJob.perform_now }
  end

  test 'nothing at all arriving is one thing to say, not thousands' do
    (ReportUncopiedUploadsJob::INDIVIDUALLY + 1).times {|i|
      webui_upload created_at: (2 + i).days.ago, arrived: false
    }

    # A submissions directory that is not where we left it would otherwise
    # arrive as an alarm for every upload ever made.
    assert_empty reports(ReportUncopiedUploadsJob::UncopiedUpload) { ReportUncopiedUploadsJob.perform_now }

    assert_match(/have no directory/,
                 reports(ReportUncopiedUploadsJob::NothingArrived) { ReportUncopiedUploadsJob.perform_now }.sole)
  end
end
