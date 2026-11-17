# A workout day trained on another weekday for one week only. The split's own plan is not changed.
class CreateWorkoutDayMoves < ActiveRecord::Migration[7.1]
  def change
    create_table :workout_day_moves do |t|
      t.references :workout_day, null: false, foreign_key: { on_delete: :cascade }, index: false
      # The Sunday the week starts on.
      t.date :week_start, null: false
      # 0 = Sunday .. 6 = Saturday: where the workout is that week.
      t.integer :weekday, null: false
      t.timestamps
    end
    add_index :workout_day_moves, [:workout_day_id, :week_start], unique: true
  end
end
