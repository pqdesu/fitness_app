class RemoveSetDataFromWorkoutLogExercises < ActiveRecord::Migration[7.1]
  def change
    remove_column :workout_log_exercises, :sets_completed, :integer
    remove_column :workout_log_exercises, :reps_completed, :integer
    remove_column :workout_log_exercises, :weight_used, :decimal
  end
end
