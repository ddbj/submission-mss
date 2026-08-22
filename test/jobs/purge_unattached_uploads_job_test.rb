require 'test_helper'

using TmpUploadedFile

class PurgeUnattachedUploadsJobTest < ActiveJob::TestCase
  def blob(service_name: 'test', created_at: 3.days.ago)
    ActiveStorage::Blob.create_and_upload!(
      io:           Rack::Test::UploadedFile.tmp('example.ann'),
      filename:     'example.ann',
      service_name: 'test'
    ).tap {
      _1.update_columns(service_name:, created_at:)
    }
  end

  test 'a blob nothing is attached to is purged' do
    old = blob

    PurgeUnattachedUploadsJob.perform_now

    assert_enqueued_with job: ActiveStorage::PurgeJob, args: [old]
  end

  test 'a blob still being offered to a submission is left alone' do
    recent = blob(created_at: 1.day.ago)

    PurgeUnattachedUploadsJob.perform_now

    assert_no_enqueued_jobs only: ActiveStorage::PurgeJob
    assert_predicate recent.reload, :persisted?
  end

  test 'a blob left in a service that is gone is reported, not purged' do
    stranded = blob(service_name: 'minio')

    reported = capture_error_reports(PurgeUnattachedUploadsJob::StrandedBlobs) do
      PurgeUnattachedUploadsJob.perform_now
    end

    # Purging it raises, so the sweep would report it once per blob -- 394 of
    # them, the night this first ran.
    assert_no_enqueued_jobs only: ActiveStorage::PurgeJob
    assert_predicate stranded.reload, :persisted?

    assert_equal 1, reported.size
    assert_match(/1 in minio/, reported.sole.error.message)
  end
end
