class CreateWorkoutLogs < ActiveRecord::Migration[7.1]
  def change
    create_table :workout_logs do |t|
      t.references :workout_day, null: false, foreign_key: true
      t.date :date
      t.text :notes

      t.timestamps
    end
  end
end
