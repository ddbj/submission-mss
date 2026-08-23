class RecordWhenAnUploadWasCopied < ActiveRecord::Migration[8.1]
  # Whether the files had been handed over was recorded on webui_uploads, where
  # only a direct upload could see it. An upload gathered from an extraction had
  # nothing to go on but its directory, and that directory sits on a filesystem
  # curators work on too: one tidied away after the submission was dealt with
  # left the nightly look for uploads that never arrived naming it every
  # morning, for good.
  #
  # So the record moves to the upload itself, where every way of arriving passes
  # through. What it said on webui_uploads was really two things at once -- the
  # files were copied, and the blobs were let go -- and the second is now asked
  # of the attachments, which answer it whether or not the purge got that far.
  #
  # webui_uploads.copied is left standing. Nothing reads it from here, but the
  # containers still serving while this runs do, and every submission made in
  # that window inserts a row naming it. It goes in a deploy of its own -- and
  # that one runs this same backfill again first: a copy those containers
  # finished after this ran set the old flag and nothing else, so the upload it
  # belongs to is still sitting here with no copied_at.
  def up
    add_column :uploads, :copied_at, :datetime

    execute <<~SQL.squish
      UPDATE uploads SET copied_at = webui_uploads.updated_at
      FROM webui_uploads
      WHERE uploads.via_type = 'WebuiUpload'
        AND uploads.via_id = webui_uploads.id
        AND webui_uploads.copied
    SQL

    backfill_from_disk
  end

  def down
    remove_column :uploads, :copied_at
  end

  private

  # Every other way of arriving says so only by having a directory. Read them
  # once, here, rather than leaving each of them to be judged by a filesystem
  # for the rest of its life. Nothing to read is not a reason to declare them
  # all uncopied: the directory is still the fallback, so they lose nothing.
  def backfill_from_disk
    root = Pathname.new(Rails.application.config_for(:app).submissions_dir!)

    return unless root.exist?

    rows = select_all(<<~SQL.squish)
      SELECT uploads.id, uploads.files_dir_name, submissions.mass_id
      FROM uploads
      JOIN submissions ON submissions.id = uploads.submission_id
      WHERE uploads.copied_at IS NULL
    SQL

    copied = rows.filter_map {
      Integer(_1['id']) if root.join(_1['mass_id'], _1['files_dir_name']).exist?
    }

    copied.each_slice(1_000) do |slice|
      execute "UPDATE uploads SET copied_at = updated_at WHERE id IN (#{slice.join(', ')})"
    end

    say "read #{copied.size} uploads off the disk", true
  end
end
