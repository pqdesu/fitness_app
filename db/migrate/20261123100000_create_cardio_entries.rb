# A cardio exercise's rows: incline, speed and time, in place of a lift's sets of weight and reps.
# A new table only, so master (which shares the development database) reads nothing new.
class CreateCardioEntries < ActiveRecord::Migration[8.1]
  def change
    create_table :cardio_entries do |t|
      t.references :workout_log_exercise, null: false, foreign_key: true
      t.integer :entry_number, null: false
      t.decimal :incline, precision: 4, scale: 1
      t.decimal :speed, precision: 4, scale: 1
      t.integer :duration_seconds, null: false
      t.timestamps
    end
    add_index :cardio_entries, [:workout_log_exercise_id, :entry_number], unique: true,
                                       name: "index_cardio_entries_on_entry_and_number"
  end
end
