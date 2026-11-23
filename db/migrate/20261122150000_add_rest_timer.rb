# The rest timer between sets: it runs on the logged exercise (Start rest, Stop) and is saved on
# the next set. All nullable or defaulted, so master's inserts keep working on the shared database.
class AddRestTimer < ActiveRecord::Migration[8.1]
  def change
    add_column :workout_log_exercises, :rest_started_at, :datetime
    add_column :workout_log_exercises, :rest_ended_at, :datetime
    add_column :workout_sets, :rest_seconds, :integer
    # Typed in whole minutes for a set logged later: shown as "~3 min".
    add_column :workout_sets, :rest_approx, :boolean, default: false, null: false
  end
end
