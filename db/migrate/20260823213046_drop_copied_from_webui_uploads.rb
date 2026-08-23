class DropCopiedFromWebuiUploads < ActiveRecord::Migration[8.1]
  # What this said moved to uploads.copied_at, where every way of arriving can
  # say it. The column stayed behind for one deploy because the containers still
  # serving through that one were inserting rows that named it; nothing reads or
  # writes it now.
  #
  # The backfill runs again first, and has to. A copy those containers finished
  # after the last one ran set this flag and nothing else, so the upload it
  # belongs to is sitting here with no copied_at -- which reads as copied for
  # exactly as long as its directory is there, and turns into a permanent false
  # positive the day a curator clears the submission away. Dropping the column
  # takes the last evidence of it with it.
  #
  # Written out again rather than shared with the migration that first ran it:
  # what a migration did is a matter of record, and a record is no use if it
  # changes underneath.
  def up
    execute <<~SQL.squish
      UPDATE uploads SET copied_at = webui_uploads.updated_at
      FROM webui_uploads
      WHERE uploads.via_type = 'WebuiUpload'
        AND uploads.via_id = webui_uploads.id
        AND webui_uploads.copied
        AND uploads.copied_at IS NULL
    SQL

    backfill_from_disk

    remove_column :webui_uploads, :copied
  end

  def down
    add_column :webui_uploads, :copied, :boolean, default: false, null: false

    execute <<~SQL.squish
      UPDATE webui_uploads SET copied = true
      FROM uploads
      WHERE uploads.via_type = 'WebuiUpload'
        AND uploads.via_id = webui_uploads.id
        AND uploads.copied_at IS NOT NULL
    SQL
  end

  private

  # Every other way of arriving says so only by having a directory. Nothing to
  # read is not a reason to declare them all uncopied: the directory is still
  # what Upload#copied? falls back to, so they lose nothing by being missed.
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
