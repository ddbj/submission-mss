# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.0].define(version: 2023_05_19_014954) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  # Custom types defined in this database.
  # Note that some types may not work with other database engines. Be careful if changing database.
  create_enum "extraction_state", ["pending", "fulfilled", "rejected"]

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "contact_people", force: :cascade do |t|
    t.bigint "submission_id", null: false
    t.string "email", null: false
    t.string "full_name", null: false
    t.string "affiliation", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["submission_id"], name: "index_contact_people_on_submission_id"
  end

  create_table "dfast_extraction_files", force: :cascade do |t|
    t.bigint "extraction_id", null: false
    t.string "name", null: false
    t.string "dfast_job_id", null: false
    t.boolean "parsing", null: false
    t.jsonb "parsed_data"
    t.jsonb "_errors"
    t.index ["extraction_id", "name"], name: "index_dfast_extraction_files_on_extraction_id_and_name", unique: true
    t.index ["extraction_id"], name: "index_dfast_extraction_files_on_extraction_id"
  end

  create_table "dfast_extractions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.enum "state", default: "pending", null: false, enum_type: "extraction_state"
    t.string "dfast_job_ids", null: false, array: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.jsonb "error"
    t.index ["user_id"], name: "index_dfast_extractions_on_user_id"
  end

  create_table "dfast_uploads", force: :cascade do |t|
    t.bigint "extraction_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["extraction_id"], name: "index_dfast_uploads_on_extraction_id"
  end

  create_table "mass_directory_extraction_files", force: :cascade do |t|
    t.bigint "extraction_id", null: false
    t.string "name", null: false
    t.boolean "parsing", null: false
    t.jsonb "parsed_data"
    t.jsonb "_errors"
    t.index ["extraction_id", "name"], name: "index_mass_directory_extraction_files_on_extraction_id_and_name", unique: true
    t.index ["extraction_id"], name: "index_mass_directory_extraction_files_on_extraction_id"
  end

  create_table "mass_directory_extractions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.enum "state", default: "pending", null: false, enum_type: "extraction_state"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.jsonb "error"
    t.index ["user_id"], name: "index_mass_directory_extractions_on_user_id"
  end

  create_table "mass_directory_uploads", force: :cascade do |t|
    t.bigint "extraction_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["extraction_id"], name: "index_mass_directory_uploads_on_extraction_id"
  end

  create_table "other_people", force: :cascade do |t|
    t.bigint "submission_id", null: false
    t.string "email", null: false
    t.string "full_name", null: false
    t.integer "position", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["position"], name: "index_other_people_on_position"
    t.index ["submission_id"], name: "index_other_people_on_submission_id"
  end

  create_table "submissions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.boolean "tpa", null: false
    t.integer "entries_count", null: false
    t.date "hold_date"
    t.string "sequencer", null: false
    t.string "data_type", null: false
    t.string "description"
    t.string "email_language", null: false
    t.virtual "mass_id", type: :string, as: "('NSUB'::text || lpad((id)::text, 6, '0'::text))", stored: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["mass_id"], name: "index_submissions_on_mass_id"
    t.index ["user_id"], name: "index_submissions_on_user_id"
  end

  create_table "uploads", force: :cascade do |t|
    t.bigint "submission_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "via_type", null: false
    t.bigint "via_id", null: false
    t.index ["submission_id"], name: "index_uploads_on_submission_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "openid_sub", null: false
    t.jsonb "id_token", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["openid_sub"], name: "index_users_on_openid_sub", unique: true
  end

  create_table "webui_uploads", force: :cascade do |t|
    t.boolean "copied", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "dfast_extraction_files", "dfast_extractions", column: "extraction_id"
  add_foreign_key "dfast_uploads", "dfast_extractions", column: "extraction_id"
  add_foreign_key "mass_directory_extraction_files", "mass_directory_extractions", column: "extraction_id"
  add_foreign_key "mass_directory_uploads", "mass_directory_extractions", column: "extraction_id"
end
