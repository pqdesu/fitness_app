class CreateWorkoutLogExercises < ActiveRecord::Migration[7.1]
  def change
    create_table :workout_log_exercises do |t|
      t.references :workout_log, null: false, foreign_key: true
      t.references :workout_exercise, null: false, foreign_key: true
      t.integer :sets_completed
      t.integer :reps_completed
      t.decimal :weight_used
      t.text :notes

      t.timestamps
    end
  end
end
