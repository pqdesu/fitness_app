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

ActiveRecord::Schema[8.1].define(version: 2026_11_17_140000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "exercises", force: :cascade do |t|
    t.string "name", null: false
    t.string "muscle_group"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index "lower((name)::text)", name: "index_exercises_on_shared_name", unique: true, where: "(user_id IS NULL)"
    t.index "user_id, lower((name)::text)", name: "index_exercises_on_own_name", unique: true, where: "(user_id IS NOT NULL)"
    t.index ["user_id"], name: "index_exercises_on_user_id"
  end

  create_table "splits", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_splits_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "admin", default: false, null: false
    t.bigint "active_split_id"
    t.string "time_zone"
    t.integer "failed_attempts", default: 0, null: false
    t.datetime "locked_at"
    t.index ["active_split_id"], name: "index_users_on_active_split_id"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  create_table "workout_day_moves", force: :cascade do |t|
    t.bigint "workout_day_id", null: false
    t.date "week_start", null: false
    t.integer "weekday", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["workout_day_id", "week_start"], name: "index_workout_day_moves_on_workout_day_id_and_week_start", unique: true
  end

  create_table "workout_days", force: :cascade do |t|
    t.bigint "split_id", null: false
    t.string "day", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "weekday", null: false
    t.index ["split_id", "weekday"], name: "index_workout_days_on_split_id_and_weekday", unique: true
    t.index ["split_id"], name: "index_workout_days_on_split_id"
  end

  create_table "workout_exercises", force: :cascade do |t|
    t.bigint "workout_day_id", null: false
    t.bigint "exercise_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "name", null: false
    t.string "equipment", default: "free_weights", null: false
    t.string "machine_brand"
    t.index ["exercise_id"], name: "index_workout_exercises_on_exercise_id"
    t.index ["workout_day_id", "exercise_id"], name: "index_workout_exercises_on_workout_day_id_and_exercise_id", unique: true, where: "(exercise_id IS NOT NULL)"
    t.index ["workout_day_id"], name: "index_workout_exercises_on_workout_day_id"
  end

  create_table "workout_log_exercises", force: :cascade do |t|
    t.bigint "workout_log_id", null: false
    t.bigint "workout_exercise_id"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "name", null: false
    t.string "equipment", default: "free_weights", null: false
    t.string "machine_brand"
    t.bigint "exercise_id"
    t.index ["exercise_id"], name: "index_workout_log_exercises_on_exercise_id"
    t.index ["workout_exercise_id"], name: "index_workout_log_exercises_on_workout_exercise_id"
    t.index ["workout_log_id", "exercise_id"], name: "index_workout_log_exercises_on_workout_log_id_and_exercise_id", unique: true, where: "(exercise_id IS NOT NULL)"
    t.index ["workout_log_id"], name: "index_workout_log_exercises_on_workout_log_id"
  end

  create_table "workout_logs", force: :cascade do |t|
    t.bigint "workout_day_id"
    t.date "date", null: false
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.string "workout", null: false
    t.boolean "rest_day", default: false, null: false
    t.index ["user_id", "workout", "date"], name: "index_workout_logs_on_user_id_and_workout_and_date", unique: true
    t.index ["user_id"], name: "index_workout_logs_on_user_id"
    t.index ["workout_day_id"], name: "index_workout_logs_on_workout_day_id"
  end

  create_table "workout_sets", force: :cascade do |t|
    t.bigint "workout_log_exercise_id", null: false
    t.integer "set_number", null: false
    t.integer "reps_completed", null: false
    t.decimal "weight_used", precision: 8, scale: 3
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["workout_log_exercise_id", "set_number"], name: "index_workout_sets_on_workout_log_exercise_id_and_set_number", unique: true
    t.index ["workout_log_exercise_id"], name: "index_workout_sets_on_workout_log_exercise_id"
  end

  add_foreign_key "exercises", "users"
  add_foreign_key "splits", "users"
  add_foreign_key "users", "splits", column: "active_split_id", on_delete: :nullify
  add_foreign_key "workout_day_moves", "workout_days", on_delete: :cascade
  add_foreign_key "workout_days", "splits"
  add_foreign_key "workout_exercises", "exercises"
  add_foreign_key "workout_exercises", "workout_days"
  add_foreign_key "workout_log_exercises", "exercises"
  add_foreign_key "workout_log_exercises", "workout_exercises"
  add_foreign_key "workout_log_exercises", "workout_logs"
  add_foreign_key "workout_logs", "users"
  add_foreign_key "workout_logs", "workout_days", on_delete: :nullify
  add_foreign_key "workout_sets", "workout_log_exercises"
end
