# The "once only" rules were checked in Ruby alone, so two requests at the same moment (a double
# tap) could both save. These indexes make the database refuse the second one.
# Every workout day has a weekday since the week became the split's layout; the column now says so.
#
# A database with rows that already break a rule cannot take the index. Before changing anything
# the migration looks for such rows and stops with one message that names them and what to do,
# instead of failing on the first index with a bare PG::UniqueViolation. It never deletes or
# merges workouts itself: which of two workouts to keep is the owner's decision.
class AddUniqueIndexesAndRequireWeekday < ActiveRecord::Migration[8.1]
  # Each rule, and the SQL that lists the rows breaking it (one line per group of duplicates).
  CHECKS = {
    "workout days without a weekday" => <<~SQL.squish,
      SELECT 'workout day ' || id::text AS rows FROM workout_days WHERE weekday IS NULL
    SQL
    "workout logs that repeat a workout on a day" => <<~SQL.squish,
      SELECT 'user ' || user_id || ', ' || workout || ' on ' || date || ': workout logs ' ||
             string_agg(id::text, ', ' ORDER BY id) ||
             CASE WHEN bool_and(notes LIKE 'Mock data%') THEN ' (all mock data)' ELSE '' END AS rows
      FROM workout_logs GROUP BY user_id, workout, date HAVING COUNT(*) > 1
    SQL
    "exercises that are twice on a workout day" => <<~SQL.squish,
      SELECT 'workout day ' || workout_day_id || ': workout exercises ' ||
             string_agg(id::text, ', ' ORDER BY id) AS rows
      FROM workout_exercises WHERE exercise_id IS NOT NULL
      GROUP BY workout_day_id, exercise_id HAVING COUNT(*) > 1
    SQL
    "exercises that are twice in a logged workout" => <<~SQL.squish,
      SELECT 'workout log ' || workout_log_id || ': entries ' ||
             string_agg(id::text, ', ' ORDER BY id) AS rows
      FROM workout_log_exercises WHERE exercise_id IS NOT NULL
      GROUP BY workout_log_id, exercise_id HAVING COUNT(*) > 1
    SQL
    "shared exercises whose names differ only in capitals" => <<~SQL.squish,
      SELECT string_agg(name || ' (' || id || ')', ', ' ORDER BY id) AS rows
      FROM exercises WHERE user_id IS NULL GROUP BY LOWER(name) HAVING COUNT(*) > 1
    SQL
    "own exercises of one user whose names differ only in capitals" => <<~SQL.squish
      SELECT 'user ' || user_id || ': ' || string_agg(name || ' (' || id || ')', ', ' ORDER BY id) AS rows
      FROM exercises WHERE user_id IS NOT NULL GROUP BY user_id, LOWER(name) HAVING COUNT(*) > 1
    SQL
  }.freeze

  def change
    reversible { |dir| dir.up { stop_on_rows_that_break_the_rules! } }

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

  # The rows that break each rule, by rule; empty when the indexes can be added.
  def rows_that_break_the_rules
    CHECKS.filter_map do |rule, sql|
      rows = connection.select_values(sql)
      [rule, rows] if rows.any?
    end.to_h
  end

  private

  def stop_on_rows_that_break_the_rules!
    found = rows_that_break_the_rules
    return if found.empty?

    lines = found.flat_map { |rule, rows| ["#{rows.size} #{rule}:", *rows.map { |row| "  - #{row}" }] }
    raise ActiveRecord::MigrationError, <<~MESSAGE
      Nothing was changed. These rows break a "once only" rule that this migration makes the
      database enforce:

      #{lines.join("\n")}

      If they are mock data, run `bin/rails mock:clear` and migrate again. Otherwise delete or
      merge the extra rows (keep the one with the sets you want), then migrate again.
    MESSAGE
  end
end
