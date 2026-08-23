require 'test_helper'

using TmpUploadedFile

class ReportUncopiedUploadsJobTest < ActiveJob::TestCase
  setup do
    @submission = submissions(:alice_submission)

    # The fixture upload is one of these too, so put its files in place and
    # leave each test to introduce the one it is about.
    uploads(:alice_upload).files_dir.mkpath
  end

  # An upload that never landed was never written down as copied either, so let
  # one follow the other unless a test is about them disagreeing. `holding` is
  # the blobs it came in still being attached, which a copy that ran to the end
  # would have let go of.
  def webui_upload(created_at:, arrived: true, copied: arrived, holding: false, submission: @submission)
    via = WebuiUpload.new

    via.files.attach Rack::Test::UploadedFile.tmp('example.ann') if holding

    submission.uploads.create!(via:, created_at:, copied_at: (created_at if copied)).tap {
      _1.files_dir.mkpath if arrived
    }
  end

  # One nobody has left a directory for, the way a submission that has been
  # dealt with and cleared away is left: the whole thing gone, not one upload's
  # files taken out of it.
  def cleared_submission
    Submission.create!(
      mass_id:        'NSUB000042',
      user:           users(:alice),
      tpa:            false,
      entries_count:  1,
      sequencer:      'ngs',
      data_type:      'wgs',
      email_language: 'en',

      contact_person: ContactPerson.new(
        email:       'alice+contact@example.com',
        full_name:   'Alice Liddell',
        affiliation: 'Wonderland Inc.'
      )
    )
  end

  def extraction_upload(created_at:, arrived: true, copied: arrived)
    extraction = dfast_extractions(:alice_dfast_extraction)

    @submission.uploads.create!(via: DfastUpload.new(extraction:), created_at:, copied_at: (created_at if copied)).tap {
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
    upload = webui_upload(created_at: 2.days.ago, holding: true)

    # The waiting room is meant to empty as the files leave it. This one did
    # not, and no sweep reaches a blob that is still attached.
    assert_equal ["the files of upload #{@submission.mass_id}/#{upload.files_dir_name} arrived, but the blobs they came in were never let go"],
                 reports(ReportUncopiedUploadsJob::UnreleasedBlobs) { ReportUncopiedUploadsJob.perform_now }
  end

  test 'files that arrived before the copy could be written down, still holding their blobs' do
    upload = webui_upload(created_at: 2.days.ago, copied: false, holding: true)

    # Two uploads sat in exactly this state for five months: the move had
    # happened, and everything after it -- the record, the purge, the mail, the
    # curator sheet -- died with the job. The directory is all the copy left
    # behind, so it has to be enough to know the blobs are owed nothing.
    assert_equal ["the files of upload #{@submission.mass_id}/#{upload.files_dir_name} arrived, but the blobs they came in were never let go"],
                 reports(ReportUncopiedUploadsJob::UnreleasedBlobs) { ReportUncopiedUploadsJob.perform_now }

    assert_empty reports(ReportUncopiedUploadsJob::UncopiedUpload) { ReportUncopiedUploadsJob.perform_now }
  end

  test 'an upload whose directory was tidied away long afterwards is not reported' do
    webui_upload      created_at: 2.days.ago, arrived: false, copied: true
    extraction_upload created_at: 2.days.ago, arrived: false, copied: true

    # Curators work on this filesystem too, and a submission dealt with a year
    # ago may not be sitting where it was left. The copy said so as it landed,
    # and that stands however the directory is treated afterwards -- for every
    # way of arriving, not only the one that happened to keep a flag.
    assert_empty reports(ReportUncopiedUploadsJob::UncopiedUpload) { ReportUncopiedUploadsJob.perform_now }
    assert_empty reports(ReportUncopiedUploadsJob::UnreleasedBlobs) { ReportUncopiedUploadsJob.perform_now }
  end

  test 'an upload that never landed is named for that, not for its blobs' do
    stuck = webui_upload(created_at: 2.days.ago, arrived: false, holding: true)

    # It is still holding them, but that is not the thing wrong with it: the
    # blobs are the only copy left of what the submitter sent.
    assert_equal ["the files of upload #{@submission.mass_id}/#{stuck.files_dir_name} never reached the submission"],
                 reports(ReportUncopiedUploadsJob::UncopiedUpload) { ReportUncopiedUploadsJob.perform_now }

    assert_empty reports(ReportUncopiedUploadsJob::UnreleasedBlobs) { ReportUncopiedUploadsJob.perform_now }
  end

  test 'an upload copied before any of this was written down is not reported' do
    webui_upload      created_at: 2.days.ago, copied: false
    extraction_upload created_at: 2.days.ago, copied: false

    # Years of uploads have nothing but their directory to show for themselves,
    # and they were all handed over. The record only starts from here.
    assert_empty reports(ReportUncopiedUploadsJob::UncopiedUpload) { ReportUncopiedUploadsJob.perform_now }
    assert_empty reports(ReportUncopiedUploadsJob::UnreleasedBlobs) { ReportUncopiedUploadsJob.perform_now }
  end

  test 'an upload whose files are in place is not reported' do
    webui_upload      created_at: 2.days.ago
    extraction_upload created_at: 2.days.ago

    assert_empty reports(ReportUncopiedUploadsJob::UncopiedUpload) { ReportUncopiedUploadsJob.perform_now }
    assert_empty reports(ReportUncopiedUploadsJob::UnreleasedBlobs) { ReportUncopiedUploadsJob.perform_now }
  end

  test 'an upload still on its way is given time to arrive' do
    webui_upload created_at: 1.hour.ago, arrived: false

    assert_empty reports(ReportUncopiedUploadsJob::UncopiedUpload) { ReportUncopiedUploadsJob.perform_now }
  end

  test 'more of them than anybody will take one at a time are named up to a point, then counted' do
    (ReportUncopiedUploadsJob::INDIVIDUALLY + 1).times {|i|
      webui_upload created_at: (2 + i).days.ago, arrived: false
    }

    # Counted rather than dropped, and the count is not in the sentence: a pile
    # that grows overnight is the same thing to answer for, not a new one.
    assert_equal ReportUncopiedUploadsJob::INDIVIDUALLY,
                 reports(ReportUncopiedUploadsJob::UncopiedUpload) { ReportUncopiedUploadsJob.perform_now }.size

    too_many = capture_error_reports(ReportUncopiedUploadsJob::TooMany) { ReportUncopiedUploadsJob.perform_now }.sole

    assert_match(/UncopiedUpload/, too_many.error.message)
    assert_equal ReportUncopiedUploadsJob::INDIVIDUALLY + 1, too_many.context.fetch(:count)
  end

  test 'how many there are is said before any of them are named' do
    (ReportUncopiedUploadsJob::INDIVIDUALLY + 1).times {|i|
      webui_upload created_at: (2 + i).days.ago, arrived: false
    }

    said = capture_error_reports { ReportUncopiedUploadsJob.perform_now }.map { _1.error.class }

    # What carries these away queues them and drops what it cannot keep up
    # with. On the night there is a lot to say, the line saying how much has to
    # be the one that gets out.
    assert_equal ReportUncopiedUploadsJob::TooMany, said.first
  end

  test 'the oldest are the ones named when there are more than will be named' do
    oldest = (ReportUncopiedUploadsJob::INDIVIDUALLY + 1).times.map {|i|
      webui_upload created_at: (2 + i).days.ago, arrived: false
    }.last

    # Whoever is working through these comes back to the same list tomorrow.
    # An upload nobody has got to yet must not be crowded out by one that
    # arrived after it.
    named = reports(ReportUncopiedUploadsJob::UncopiedUpload) { ReportUncopiedUploadsJob.perform_now }

    assert_includes named, "the files of upload #{@submission.mass_id}/#{oldest.files_dir_name} never reached the submission"
  end

  test 'exactly as many as will be taken one at a time are all named' do
    ReportUncopiedUploadsJob::INDIVIDUALLY.times {|i|
      webui_upload created_at: (2 + i).days.ago, arrived: false
    }

    assert_equal ReportUncopiedUploadsJob::INDIVIDUALLY,
                 reports(ReportUncopiedUploadsJob::UncopiedUpload) { ReportUncopiedUploadsJob.perform_now }.size

    assert_empty reports(ReportUncopiedUploadsJob::TooMany) { ReportUncopiedUploadsJob.perform_now }
  end

  test 'files copied days ago that are not where they were put' do
    upload = webui_upload(created_at: 3.days.ago, arrived: false, copied: true)

    # Nobody has finished with a submission from this week, so nobody tidied it
    # away. This is the ground the files were standing on.
    assert_equal ["the files of upload #{@submission.mass_id}/#{upload.files_dir_name} were copied, and are not where they were put"],
                 reports(ReportUncopiedUploadsJob::VanishedFiles) { ReportUncopiedUploadsJob.perform_now }

    assert_empty reports(ReportUncopiedUploadsJob::UncopiedUpload) { ReportUncopiedUploadsJob.perform_now }
  end

  test 'a submission cleared away days after the copy is too soon to be housekeeping' do
    upload = webui_upload(created_at: 3.days.ago, arrived: false, copied: true, submission: cleared_submission)

    # Nothing is left to point at, but nobody has finished with a submission
    # from this week either, so its going is not somebody tidying up.
    assert_equal ["the files of upload #{upload.submission.mass_id}/#{upload.files_dir_name} were copied, and are not where they were put"],
                 reports(ReportUncopiedUploadsJob::VanishedFiles) { ReportUncopiedUploadsJob.perform_now }
  end

  test 'a submission still standing without its files is the ground moving, however long ago' do
    upload = webui_upload(created_at: 200.days.ago, arrived: false, copied: true)

    # Curators clear away the whole submission, so one left standing with an
    # upload's files taken out of it is not housekeeping, whatever its age.
    assert_equal ["the files of upload #{@submission.mass_id}/#{upload.files_dir_name} were copied, and are not where they were put"],
                 reports(ReportUncopiedUploadsJob::VanishedFiles) { ReportUncopiedUploadsJob.perform_now }
  end

  test 'a history of submissions cleared away does not swallow the one that matters' do
    cleared = cleared_submission

    (ReportUncopiedUploadsJob::INDIVIDUALLY + 5).times {|i|
      webui_upload created_at: (90 + i).days.ago, arrived: false, copied: true, submission: cleared
    }

    stuck = webui_upload(created_at: 2.days.ago, arrived: false)

    # Curators only ever add to this pile, so anything counting it would sooner
    # or later be answer enough on its own -- and from then on nothing would be
    # named again, ever. What separates them is what is left behind and how
    # long ago the copy was.
    assert_equal ["the files of upload #{@submission.mass_id}/#{stuck.files_dir_name} never reached the submission"],
                 reports(ReportUncopiedUploadsJob::UncopiedUpload) { ReportUncopiedUploadsJob.perform_now }

    assert_empty reports(ReportUncopiedUploadsJob::VanishedFiles) { ReportUncopiedUploadsJob.perform_now }
    assert_empty reports(ReportUncopiedUploadsJob::TooMany) { ReportUncopiedUploadsJob.perform_now }
  end

  test 'an upload that arrived another way is not read as a direct one holding blobs' do
    holding = webui_upload(created_at: 2.days.ago, holding: true)

    # The ids come from webui_uploads, and every other way of arriving numbers
    # its own table from one. Two rows with the same id are not one upload.
    imported = extraction_upload(created_at: 2.days.ago)

    DfastUpload.where(id: imported.via_id).update_all(id: holding.via_id)
    imported.update_column :via_id, holding.via_id

    assert_equal ["the files of upload #{@submission.mass_id}/#{holding.files_dir_name} arrived, but the blobs they came in were never let go"],
                 reports(ReportUncopiedUploadsJob::UnreleasedBlobs) { ReportUncopiedUploadsJob.perform_now }
  end
end
