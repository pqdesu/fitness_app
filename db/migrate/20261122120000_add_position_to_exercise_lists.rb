# Exercises keep an order: a day's plan, and each logged workout's (see Positioned). A row is only
# numbered once its list is reordered; until then it is NULL, which PostgreSQL sorts last, so
# existing rows, new rows and rows added from a checkout that does not know the column all stay in
# the order they were added. Only adds.
class AddPositionToExerciseLists < ActiveRecord::Migration[8.1]
  def change
    add_column :workout_exercises, :position, :integer
    add_column :workout_log_exercises, :position, :integer
  end
end
