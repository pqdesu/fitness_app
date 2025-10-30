class CreateWorkoutExercises < ActiveRecord::Migration[7.1]
  def change
    create_table :workout_exercises do |t|
      t.references :workout_day, null: false, foreign_key: true
      t.references :exercise, null: false, foreign_key: true
      t.integer :sets
      t.integer :reps
      t.decimal :target_weight

      t.timestamps
    end
  end
end
