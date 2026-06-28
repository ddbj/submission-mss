class CreateGgsExtractionsAndUploads < ActiveRecord::Migration[8.1]
  def change
    create_table :ggs_extractions do |t|
      t.references :user, null: false

      t.enum   :state, null: false, default: :pending, enum_type: :extraction_state
      t.string :ggs_job_ids, array: true, null: false
      t.jsonb  :error

      t.timestamps
    end

    create_table :ggs_extraction_files do |t|
      t.references :extraction, null: false, foreign_key: {to_table: :ggs_extractions}

      t.string  :name,       null: false
      t.string  :ggs_job_id, null: false

      t.boolean :parsing,    null: false
      t.jsonb   :parsed_data
      t.jsonb   :_errors

      t.index %i[extraction_id ggs_job_id name], unique: true
    end

    create_table :ggs_uploads do |t|
      t.references :extraction, foreign_key: {to_table: :ggs_extractions}

      t.timestamps
    end
  end
end
