# The workout timer: when a workout started and ended, and whether a user's timer starts on its
# own when a workout is logged. Additive: existing workouts have no times and the older code
# ignores the columns.
class AddTimerToWorkoutLogs < ActiveRecord::Migration[8.1]
  def change
    add_column :workout_logs, :started_at, :datetime
    add_column :workout_logs, :ended_at, :datetime
    add_column :users, :timer_auto_start, :boolean, default: false, null: false
  end
end
