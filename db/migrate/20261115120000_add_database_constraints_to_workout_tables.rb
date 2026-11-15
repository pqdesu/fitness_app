class AddDatabaseConstraintsToWorkoutTables < ActiveRecord::Migration[7.1]
  def change
    change_column_null :exercises, :name, false
    change_column_null :splits, :name, false
    change_column_null :workout_days, :day, false
    change_column_null :workout_days, :order_index, false
    change_column_null :workout_exercises, :sets, false
    change_column_null :workout_exercises, :reps, false
    change_column_null :workout_logs, :date, false
    change_column_null :workout_sets, :set_number, false
    change_column_null :workout_sets, :reps_completed, false

    add_index :workout_sets, [:workout_log_exercise_id, :set_number], unique: true
  end
end
