# The "once only" rules were checked in Ruby alone, so two requests at the same moment (a double
# tap) could both save. These indexes make the database refuse the second one.
# Every workout day has a weekday since the week became the split's layout; the column now says so.
class AddUniqueIndexesAndRequireWeekday < ActiveRecord::Migration[7.1]
  def change
    change_column_null :workout_days, :weekday, false

    # One logged workout per workout per day. Legs and Lower being the same workout stays a model rule.
    remove_index :workout_logs, [:user_id, :workout, :date]
    add_index :workout_logs, [:user_id, :workout, :date], unique: true

    # An exercise is on a workout day once and in a logged workout once.
    add_index :workout_exercises, [:workout_day_id, :exercise_id], unique: true, where: "exercise_id IS NOT NULL"
    add_index :workout_log_exercises, [:workout_log_id, :exercise_id], unique: true, where: "exercise_id IS NOT NULL"

    # One of each name in the catalogue, and one among a user's own, whatever the capitals.
    add_index :exercises, "LOWER(name)", unique: true, where: "user_id IS NULL", name: "index_exercises_on_shared_name"
    add_index :exercises, "user_id, LOWER(name)", unique: true, where: "user_id IS NOT NULL", name: "index_exercises_on_own_name"
  end
end
