class CreateExtractionsAndUploads < ActiveRecord::Migration[7.0]
  def change
    create_enum :extraction_state, %i(pending fulfilled rejected)

    create_table :dfast_extractions do |t|
      t.references :user, null: false

      t.enum   :state, null: false, default: :pending, enum_type: :extraction_state
      t.string :dfast_job_ids, array: true, null: false

      t.timestamps
    end

    create_table :dfast_extraction_files do |t|
      t.references :extraction, null: false, foreign_key: {to_table: :dfast_extractions}

      t.string  :name,         null: false
      t.string  :dfast_job_id, null: false

      t.boolean :parsing,      null: false
      t.jsonb   :parsed_data
      t.jsonb   :_errors

      t.index %i(extraction_id name), unique: true
    end

    create_table :mass_directory_extractions do |t|
      t.references :user, null: false

      t.enum :state, null: false, default: :pending, enum_type: :extraction_state

      t.timestamps
    end

    create_table :mass_directory_extraction_files do |t|
      t.references :extraction, null: false, foreign_key: {to_table: :mass_directory_extractions}

      t.string  :name,    null: false

      t.boolean :parsing, null: false
      t.jsonb   :parsed_data
      t.jsonb   :_errors

      t.index %i(extraction_id name), unique: true
    end

    create_table :webui_uploads do |t|
      t.boolean :copied, null: false, default: false

      t.timestamps
    end

    reversible do |dir|
      dir.up do
        execute <<~SQL
          INSERT INTO webui_uploads ( id, copied, created_at, updated_at )
          SELECT id, copied, created_at, updated_at FROM uploads
        SQL
      end
    end

    create_table :dfast_uploads do |t|
      t.references :extraction, foreign_key: {to_table: :dfast_extractions}

      t.timestamps
    end

    create_table :mass_directory_uploads do |t|
      t.references :extraction, foreign_key: {to_table: :mass_directory_extractions}

      t.timestamps
    end

    change_table :uploads do |t|
      t.string :via_type
      t.bigint :via_id
    end

    reversible do |dir|
      dir.up do
        execute <<~SQL
          UPDATE uploads SET via_type = 'WebuiUpload', via_id = id
        SQL
      end
    end

    change_column_null :uploads, :via_type, false
    change_column_null :uploads, :via_id,   false

    remove_column :uploads, :copied, :boolean, null: false, default: false
  end
end
