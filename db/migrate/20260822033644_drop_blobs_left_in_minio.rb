class DropBlobsLeftInMinio < ActiveRecord::Migration[8.1]
  SERVICE = 'minio'.freeze

  # MinIO was replaced by SeaweedFS in March (0ced0557) without moving what was
  # in it, so the blobs made before that still name a service nothing is
  # configured for. What they point at went with it: they cannot be purged, only
  # dropped, and until they are, the nightly sweep tries to purge them and fails
  # once for each.
  #
  # Only the ones nothing is attached to. A blob some upload still holds is as
  # unreachable, but the attachment is a record of what was sent, and that is
  # not this migration's to throw away. How many those are is worth knowing:
  # each one belongs to an upload whose files were never copied into place.
  def up
    service = connection.quote(SERVICE)

    attached = select_value(<<~SQL.squish)
      SELECT COUNT(*) FROM active_storage_blobs b
      WHERE b.service_name = #{service}
        AND EXISTS (SELECT 1 FROM active_storage_attachments a WHERE a.blob_id = b.id)
    SQL

    dropped = execute(<<~SQL.squish).cmd_tuples
      DELETE FROM active_storage_blobs b
      WHERE b.service_name = #{service}
        AND NOT EXISTS (SELECT 1 FROM active_storage_attachments a WHERE a.blob_id = b.id)
    SQL

    say "dropped #{dropped} blobs left in #{SERVICE}, and left #{attached} that something is still attached to", true
  end

  # Nothing to undo: what these rows named went with the service, so putting
  # them back would name it still. Left open so the schema can be rolled past.
  def down; end
end
