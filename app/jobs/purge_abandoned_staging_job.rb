require 'find'

class PurgeAbandonedStagingJob < ApplicationJob
  # Left behind and will not go away. Said once at the end rather than raised
  # where it happens, so that one directory that will not go does not keep the
  # others from going.
  class StuckStaging < StandardError; end

  # What stage_files names its directories. Nothing else has any business being
  # in there, but this is a job whose whole trade is removing directories: it
  # takes only the ones it can account for.
  STAGED = /\ANSUB\d+-\d+\z/

  # How long a staging directory is left alone. A copy that is running touches
  # its own as it writes, so this is not a race with one in progress: it is how
  # long after a copy stops writing we are prepared to believe it is not coming
  # back. Generous, because a submission can be a great many gigabytes.
  RETENTION = 1.day

  queue_as :default

  # A copy clears up after itself, but only when it is given the chance: a
  # container killed part way through leaves the files it had gathered so far
  # where nothing will ever look at them again, and the next attempt gathers its
  # own. Five of those had been sitting there since March, holding 82MB of
  # copies of files that had long since reached their submissions.
  def perform
    staging_dir = Submission.staging_dir

    return unless staging_dir.exist?

    stuck = staging_dir.children.select { STAGED.match?(_1.basename.to_s) && abandoned?(_1) }.reject { remove(_1) }

    return if stuck.empty?

    Rails.error.report(
      StuckStaging.new('what a stopped copy left behind will not go away'),
      handled: true,
      context:  {directories: stuck.map(&:to_s)}
    )
  end

  private

  def abandoned?(dir)
    last_touched(dir)&.before?(RETENTION.ago) || false
  end

  # Asked of everything inside as well as of the directory itself, dot-named
  # files included. Adding a file is what moves a directory's own time, so one
  # being filled a byte at a time -- which is what a large copy looks like for
  # most of its life -- would otherwise read as untouched since it started.
  #
  # lstat, so a symlink is asked about itself: following one that points nowhere
  # raises, and a broken link is no reason to stop looking at the rest. Anything
  # that goes while we are looking counts as still in use, since the only thing
  # that takes these away is a copy finishing with one.
  def last_touched(dir)
    Find.find(dir.to_s).map { File.lstat(_1).mtime }.max
  rescue Errno::ENOENT
    nil
  end

  # rmtree is rm_rf, which reports nothing at all -- not a missing directory,
  # which is what we want, and not one it could not remove, which we do.
  def remove(dir)
    dir.rmtree

    !dir.exist?
  end
end
