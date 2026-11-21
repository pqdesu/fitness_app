# The workout timer can be paused and resumed before it is stopped: paused_at is when it was paused
# (empty while it runs), and the time between each Pause and Resume adds up in paused_seconds, left
# out of the workout's recorded time. Additive: the older code ignores both.
class AddPausedSecondsToWorkoutLogs < ActiveRecord::Migration[8.1]
  def change
    add_column :workout_logs, :paused_at, :datetime
    add_column :workout_logs, :paused_seconds, :integer, default: 0, null: false
  end
end
