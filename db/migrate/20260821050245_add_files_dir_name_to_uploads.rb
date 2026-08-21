class AddFilesDirNameToUploads < ActiveRecord::Migration[8.1]
  TIMESTAMP_FORMAT = '%Y%m%d-%H%M%S'

  def up
    add_column :uploads, :files_dir_name, :string

    backfill

    change_column_null :uploads, :files_dir_name, false

    add_index :uploads, %i[submission_id files_dir_name], unique: true

    # Now led by the composite above, which answers every lookup it did.
    remove_index :uploads, :submission_id
  end

  def down
    add_index    :uploads, :submission_id
    remove_index :uploads, %i[submission_id files_dir_name], unique: true
    remove_column :uploads, :files_dir_name
  end

  private

  # The name each upload was worked out to have until now, so that every
  # directory already handed over to a curator keeps the name it was handed over
  # under. Written here rather than in SQL because the moment is read in the
  # application's time zone, and to_char would read it in the database's.
  #
  # Two uploads of one submission made in the same second shared a directory --
  # the reason for this column. They cannot both keep that name, so the later
  # one takes the suffix it would be given today; its directory is the one they
  # shared, which is now the earlier upload's alone.
  def backfill
    uploads = Class.new(ActiveRecord::Base) { self.table_name = 'uploads' }

    uploads.order(:id).group_by(&:submission_id).each_value do |group|
      taken = []

      group.each do |upload|
        base = upload.created_at.strftime(TIMESTAMP_FORMAT)
        name = (0..).lazy.map { _1.zero? ? base : "#{base}-#{_1}" }.find { taken.exclude?(_1) }

        # Named, because it is the only record there will be of which uploads
        # were affected: this one shared a directory that is now the earlier
        # upload's alone, and has none of its own to be sent to.
        say "upload #{upload.id} shared #{base}, and is #{name} now", true unless name == base

        taken << name

        upload.update_column :files_dir_name, name
      end
    end
  end
end
