class CreateWorkoutSets < ActiveRecord::Migration[7.1]
  def change
    create_table :workout_sets do |t|
      t.references :workout_log_exercise, null: false, foreign_key: true
      t.integer :set_number
      t.integer :reps_completed
      t.decimal :weight_used
      t.text :notes

      t.timestamps
    end
  end
end
