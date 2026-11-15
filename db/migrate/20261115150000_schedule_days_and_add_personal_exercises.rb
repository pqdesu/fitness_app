# - A workout day sits on a weekday (0 = Sunday .. 6 = Saturday) instead of a free position.
# - A plan only lists exercises; sets, reps and weight are recorded when training.
# - Users can create their own exercises; an exercise without a user is in the shared catalogue.
class ScheduleDaysAndAddPersonalExercises < ActiveRecord::Migration[7.1]
  def up
    add_reference :exercises, :user, foreign_key: true

    remove_column :workout_exercises, :sets
    remove_column :workout_exercises, :reps
    remove_column :workout_exercises, :target_weight

    add_column :workout_days, :weekday, :integer
    assign_weekdays
    remove_column :workout_days, :order_index
    add_index :workout_days, [:split_id, :weekday], unique: true
  end

  def down
    remove_index :workout_days, [:split_id, :weekday]
    add_column :workout_days, :order_index, :integer
    execute "UPDATE workout_days SET order_index = COALESCE(weekday, 6) + 1"
    change_column_null :workout_days, :order_index, false
    remove_column :workout_days, :weekday

    add_column :workout_exercises, :sets, :integer, null: false, default: 3
    add_column :workout_exercises, :reps, :integer, null: false, default: 10
    add_column :workout_exercises, :target_weight, :decimal
    change_column_default :workout_exercises, :sets, nil
    change_column_default :workout_exercises, :reps, nil

    execute "DELETE FROM exercises WHERE user_id IS NOT NULL AND id NOT IN (SELECT exercise_id FROM workout_exercises WHERE exercise_id IS NOT NULL)"
    remove_reference :exercises, :user, foreign_key: true
  end

  private

  # A day named after a weekday ("Monday") goes on that weekday. The others take the free
  # weekdays in their old order, starting on Monday. An eighth day in a split stays unscheduled.
  def assign_weekdays
    names = Date::DAYNAMES.map(&:downcase)
    rows = select_rows("SELECT id, split_id, day FROM workout_days ORDER BY split_id, order_index, id")

    rows.group_by { |row| row[1] }.each_value do |days|
      taken = {}
      days.each do |id, _split_id, day|
        weekday = names.index(day.to_s.strip.downcase)
        taken[weekday] = id if weekday && !taken.key?(weekday)
      end

      free = [1, 2, 3, 4, 5, 6, 0] - taken.keys
      (days.map(&:first) - taken.values).each do |id|
        weekday = free.shift
        break if weekday.nil?

        taken[weekday] = id
      end

      taken.each do |weekday, id|
        execute "UPDATE workout_days SET weekday = #{weekday.to_i} WHERE id = #{id.to_i}"
      end
    end
  end
end
