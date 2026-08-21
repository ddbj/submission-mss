class TightenGgsExtractionFileUniqueness < ActiveRecord::Migration[8.1]
  def up
    # Two GGS jobs could each bring a file of the same name. They were kept
    # apart under their own job here, but the submission they were copied to
    # holds them in one directory, so only the last one copied ever reached the
    # curator. Keep that one, which is the last the copy walks over.
    execute <<~SQL.squish
      DELETE FROM ggs_extraction_files
      WHERE id NOT IN (
        SELECT MAX(id) FROM ggs_extraction_files GROUP BY extraction_id, name
      )
    SQL

    remove_index :ggs_extraction_files, %i[extraction_id ggs_job_id name], unique: true
    add_index    :ggs_extraction_files, %i[extraction_id name],            unique: true
  end

  def down
    remove_index :ggs_extraction_files, %i[extraction_id name],            unique: true
    add_index    :ggs_extraction_files, %i[extraction_id ggs_job_id name], unique: true
  end
end
