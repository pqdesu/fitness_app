# A logged workout is the user's record of a workout (Push, Legs, ...), not a part of a split.
# It now belongs to the user and remembers which workout it was, so deleting a workout day or
# a whole split keeps the history.
class MakeWorkoutLogsOutliveSplits < ActiveRecord::Migration[7.1]
  def up
    add_reference :workout_logs, :user, foreign_key: true
    add_column :workout_logs, :workout, :string

    execute <<~SQL
      UPDATE workout_logs
      SET user_id = splits.user_id, workout = workout_days.day
      FROM workout_days JOIN splits ON splits.id = workout_days.split_id
      WHERE workout_days.id = workout_logs.workout_day_id
    SQL

    change_column_null :workout_logs, :user_id, false
    change_column_null :workout_logs, :workout, false
    add_index :workout_logs, [:user_id, :workout, :date]

    change_column_null :workout_logs, :workout_day_id, true
    remove_foreign_key :workout_logs, :workout_days
    add_foreign_key :workout_logs, :workout_days, on_delete: :nullify
  end

  def down
    # Logs whose workout day is gone cannot go back to requiring one.
    execute "DELETE FROM workout_sets WHERE workout_log_exercise_id IN (SELECT id FROM workout_log_exercises WHERE workout_log_id IN (SELECT id FROM workout_logs WHERE workout_day_id IS NULL))"
    execute "DELETE FROM workout_log_exercises WHERE workout_log_id IN (SELECT id FROM workout_logs WHERE workout_day_id IS NULL)"
    execute "DELETE FROM workout_logs WHERE workout_day_id IS NULL"

    remove_foreign_key :workout_logs, :workout_days
    add_foreign_key :workout_logs, :workout_days
    change_column_null :workout_logs, :workout_day_id, false
    remove_index :workout_logs, [:user_id, :workout, :date]
    remove_column :workout_logs, :workout
    remove_reference :workout_logs, :user, foreign_key: true
  end
end
