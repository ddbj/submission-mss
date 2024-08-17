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

ActiveRecord::Schema[7.2].define(version: 2024_08_16_115051) do
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

  create_table "solid_queue_blocked_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "queue_name", null: false
    t.integer "priority", default: 0, null: false
    t.string "concurrency_key", null: false
    t.datetime "expires_at", null: false
    t.datetime "created_at", null: false
    t.index ["concurrency_key", "priority", "job_id"], name: "index_solid_queue_blocked_executions_for_release"
    t.index ["expires_at", "concurrency_key"], name: "index_solid_queue_blocked_executions_for_maintenance"
    t.index ["job_id"], name: "index_solid_queue_blocked_executions_on_job_id", unique: true
  end

  create_table "solid_queue_claimed_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.bigint "process_id"
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_claimed_executions_on_job_id", unique: true
    t.index ["process_id", "job_id"], name: "index_solid_queue_claimed_executions_on_process_id_and_job_id"
  end

  create_table "solid_queue_failed_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.text "error"
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_failed_executions_on_job_id", unique: true
  end

  create_table "solid_queue_jobs", force: :cascade do |t|
    t.string "queue_name", null: false
    t.string "class_name", null: false
    t.text "arguments"
    t.integer "priority", default: 0, null: false
    t.string "active_job_id"
    t.datetime "scheduled_at"
    t.datetime "finished_at"
    t.string "concurrency_key"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active_job_id"], name: "index_solid_queue_jobs_on_active_job_id"
    t.index ["class_name"], name: "index_solid_queue_jobs_on_class_name"
    t.index ["finished_at"], name: "index_solid_queue_jobs_on_finished_at"
    t.index ["queue_name", "finished_at"], name: "index_solid_queue_jobs_for_filtering"
    t.index ["scheduled_at", "finished_at"], name: "index_solid_queue_jobs_for_alerting"
  end

  create_table "solid_queue_pauses", force: :cascade do |t|
    t.string "queue_name", null: false
    t.datetime "created_at", null: false
    t.index ["queue_name"], name: "index_solid_queue_pauses_on_queue_name", unique: true
  end

  create_table "solid_queue_processes", force: :cascade do |t|
    t.string "kind", null: false
    t.datetime "last_heartbeat_at", null: false
    t.bigint "supervisor_id"
    t.integer "pid", null: false
    t.string "hostname"
    t.text "metadata"
    t.datetime "created_at", null: false
    t.index ["last_heartbeat_at"], name: "index_solid_queue_processes_on_last_heartbeat_at"
    t.index ["supervisor_id"], name: "index_solid_queue_processes_on_supervisor_id"
  end

  create_table "solid_queue_ready_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "queue_name", null: false
    t.integer "priority", default: 0, null: false
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_ready_executions_on_job_id", unique: true
    t.index ["priority", "job_id"], name: "index_solid_queue_poll_all"
    t.index ["queue_name", "priority", "job_id"], name: "index_solid_queue_poll_by_queue"
  end

  create_table "solid_queue_recurring_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "task_key", null: false
    t.datetime "run_at", null: false
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_recurring_executions_on_job_id", unique: true
    t.index ["task_key", "run_at"], name: "index_solid_queue_recurring_executions_on_task_key_and_run_at", unique: true
  end

  create_table "solid_queue_recurring_tasks", force: :cascade do |t|
    t.string "key", null: false
    t.string "schedule", null: false
    t.string "command", limit: 2048
    t.string "class_name"
    t.text "arguments"
    t.string "queue_name"
    t.integer "priority", default: 0
    t.boolean "static", default: true
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_solid_queue_recurring_tasks_on_key", unique: true
    t.index ["static"], name: "index_solid_queue_recurring_tasks_on_static"
  end

  create_table "solid_queue_scheduled_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "queue_name", null: false
    t.integer "priority", default: 0, null: false
    t.datetime "scheduled_at", null: false
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_scheduled_executions_on_job_id", unique: true
    t.index ["scheduled_at", "priority", "job_id"], name: "index_solid_queue_dispatch_all"
  end

  create_table "solid_queue_semaphores", force: :cascade do |t|
    t.string "key", null: false
    t.integer "value", default: 1, null: false
    t.datetime "expires_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["expires_at"], name: "index_solid_queue_semaphores_on_expires_at"
    t.index ["key", "value"], name: "index_solid_queue_semaphores_on_key_and_value"
    t.index ["key"], name: "index_solid_queue_semaphores_on_key", unique: true
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
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "mass_id", null: false
    t.index ["mass_id"], name: "index_submissions_on_mass_id", unique: true
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
  add_foreign_key "solid_queue_blocked_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_claimed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_failed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_ready_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_recurring_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_scheduled_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
end
