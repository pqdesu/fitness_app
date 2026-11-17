# Marks a workout that was logged on a rest day of its split (the user trained anyway). Additive:
# existing logs keep false and the older code ignores the column.
class AddRestDayToWorkoutLogs < ActiveRecord::Migration[7.1]
  def change
    add_column :workout_logs, :rest_day, :boolean, default: false, null: false
  end
end
