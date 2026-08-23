require 'test_helper'
require 'find'

class PurgeAbandonedStagingJobTest < ActiveJob::TestCase
  def staging(name = 'NSUB000001-1', age:, files: {'example.ann' => 'COMMON'})
    dir = Submission.staging_dir.join(name)

    aged dir, age, files
  end

  def aged(dir, age, files)
    dir.mkpath

    files.each do |filename, content|
      dir.join(filename).dirname.mkpath
      dir.join(filename).write content
    end

    Find.find(dir.to_s).each do |path|
      File.utime age.to_time, age.to_time, path
    end

    dir
  end

  test 'what a copy had gathered when it was stopped is let go' do
    dir = staging(age: 2.days.ago)

    PurgeAbandonedStagingJob.perform_now

    assert_not dir.exist?
  end

  test 'a copy that is still going is left alone' do
    dir = staging(age: 1.minute.ago)

    PurgeAbandonedStagingJob.perform_now

    assert_predicate dir, :exist?
  end

  test 'a copy still writing into a directory it made long ago is left alone' do
    dir = staging(age: (PurgeAbandonedStagingJob::RETENTION + 1.hour).ago)

    # Adding a file is what moves a directory's own time, so a large copy that
    # started yesterday and is still writing the file it started with looks
    # untouched from the outside. What it is writing does not.
    File.utime Time.current.to_time, Time.current.to_time, dir.join('example.ann')

    PurgeAbandonedStagingJob.perform_now

    assert_predicate dir, :exist?
  end

  test 'an empty directory from an attempt that got nowhere is let go' do
    dir = staging(age: (PurgeAbandonedStagingJob::RETENTION + 1.hour).ago, files: {})

    PurgeAbandonedStagingJob.perform_now

    assert_not dir.exist?
  end

  test 'a copy stages where this sweeps' do
    extraction = dfast_extractions(:alice_dfast_extraction)

    extraction.working_dir.mkpath
    extraction.files.create!(name: 'example.ann', dfast_job_id: 'job-1', parsing: false)
    extraction.working_dir.join('example.ann').write "COMMON\tSUBMITTER\t\tcontact\tAlice Liddell\n"

    upload = submissions(:alice_submission).uploads.create!(via: DfastUpload.new(extraction:), created_at: 1.hour.ago)
    staged = nil

    FileUtils.stub :cp, ->(source, destination) { staged = destination; FileUtils.copy(source, destination) } do
      CopySubmissionFilesJob.perform_now upload
    end

    # A copy clears up after itself, so the only ones left for this to find are
    # the ones nothing was left running to clear up -- which means nothing ties
    # the two ends together except that they name the same place. Asked here so
    # that moving one and not the other is a failure rather than a sweep that
    # quietly stops sweeping.
    assert_equal Submission.staging_dir, staged.parent
  end

  test 'a dot-named file is what the copy was still writing too' do
    dir = staging(age: 2.days.ago, files: {'.example.ann' => 'COMMON'})

    # Nothing between the submitter and the disk turns a leading dot down, and
    # a directory's own time does not move for a file being rewritten. If the
    # only thing in there is invisible to this, a copy that is still going
    # reads as one that stopped a day ago.
    File.utime Time.current.to_time, Time.current.to_time, dir.join('.example.ann')

    PurgeAbandonedStagingJob.perform_now

    assert_predicate dir, :exist?
  end

  test 'a directory below the one being staged is looked into as well' do
    dir = staging(age: 2.days.ago, files: {'nested/example.ann' => 'COMMON'})

    File.utime Time.current.to_time, Time.current.to_time, dir.join('nested/example.ann')

    PurgeAbandonedStagingJob.perform_now

    assert_predicate dir, :exist?
  end

  test 'a link pointing nowhere is not a reason to leave a directory standing' do
    linked = staging('NSUB000001-8', age: 2.days.ago, files: {})

    linked.join('gone').make_symlink 'nowhere'

    [linked, linked.join('gone')].each do |path|
      File.lutime 2.days.ago.to_time, 2.days.ago.to_time, path
    end

    # Asked about the link itself rather than about what it points at, which is
    # not there. A directory holding one would otherwise never look untouched,
    # and would sit here for good.
    PurgeAbandonedStagingJob.perform_now

    assert_not linked.exist?
  end

  test 'one that goes while we are looking at it does not stop the rest' do
    going     = staging('NSUB000001-6', age: 2.days.ago)
    abandoned = staging('NSUB000001-7', age: 2.days.ago)

    lstat = File.method(:lstat)

    # The only thing that takes one of these away is a copy finishing with it,
    # and that happens while this is running. A sweep that stops at its first
    # casualty looks exactly like one with nothing left to do.
    File.stub :lstat, ->(path) { raise Errno::ENOENT, path.to_s if path.to_s.start_with?(going.to_s); lstat.call(path) } do
      PurgeAbandonedStagingJob.perform_now
    end

    assert_not abandoned.exist?
  end

  test 'something else that found its way in there is not this to remove' do
    other = Submission.staging_dir.join('NSUB000001')

    aged other, 2.days.ago, {'example.ann' => 'COMMON'}

    # This is a job whose whole trade is removing directories, so it takes only
    # the ones it can account for. A submission's own directory is named like
    # this one, and pointed a level too high that is what it would find.
    PurgeAbandonedStagingJob.perform_now

    assert_predicate other, :exist?
  end

  test "a submission's own directory is not something this removes" do
    submission = submissions(:alice_submission)

    aged submission.root_dir, 2.days.ago, {'20220101-000000/example.ann' => 'COMMON'}

    # Submissions sit untouched for weeks -- curators only clear them away once
    # they are finished, which is the whole reason the nightly report cannot go
    # by age alone. Staging is off to one side of them, not among them.
    assert_not_equal submission.root_dir.dirname, Submission.staging_dir
    PurgeAbandonedStagingJob.perform_now

    assert_predicate submission.root_dir.join('20220101-000000/example.ann'), :exist?
  end

  test 'one that will not go away is said out loud' do
    dir = staging(age: 2.days.ago)

    stuck = capture_error_reports(PurgeAbandonedStagingJob::StuckStaging) {
      FileUtils.stub :rm_rf, ->(*, **) { } do
        PurgeAbandonedStagingJob.perform_now
      end
    }.sole

    # rm_rf reports nothing at all, so a directory that cannot be removed --
    # left by a deploy that changed the user we run as, say -- would otherwise
    # sit there exactly as silently as the ones this job exists to find.
    assert_equal [dir.to_s], stuck.context.fetch(:directories)
  end

  test 'nothing having been staged yet is not a failure' do
    assert_not Submission.staging_dir.exist?

    assert_nothing_raised do
      PurgeAbandonedStagingJob.perform_now
    end
  end
end
