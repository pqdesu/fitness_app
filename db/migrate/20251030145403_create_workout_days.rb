class CreateWorkoutDays < ActiveRecord::Migration[7.1]
  def change
    create_table :workout_days do |t|
      t.references :split, null: false, foreign_key: true
      t.string :day
      t.integer :order_index

      t.timestamps
    end
  end
end
