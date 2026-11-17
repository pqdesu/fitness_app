require "test_helper"
require Rails.root.join("db/migrate/20261117140000_add_unique_indexes_and_require_weekday")

# The migration that adds the "once only" indexes first looks for rows that break the rules
# and stops with a message naming them. The test database already has the indexes, so each
# test drops the one it needs out of the way; PostgreSQL undoes that with the test's transaction.
class AddUniqueIndexesPrecheckTest < ActiveSupport::TestCase
  setup do
    @migration = AddUniqueIndexesAndRequireWeekday.new
    @migration.verbose = false
    @user = User.create!(email: "lifter@example.com", password: "secret123")
    @day = @user.splits.create!(name: "PPL").workout_days.create!(day: "Upper", weekday: 1)
  end

  test "clean data passes the check" do
    @day.workout_logs.create!(date: Date.current)
    assert_empty @migration.rows_that_break_the_rules
  end

  test "a workout repeated on a day stops the migration before anything changes, with what to do" do
    connection = ActiveRecord::Base.connection
    connection.remove_index :workout_logs, [:user_id, :workout, :date]
    first = @day.workout_logs.create!(date: Date.current, notes: "Mock data")
    second = WorkoutLog.new(user: @user, workout: "Upper", date: Date.current, notes: "Mock data")
    second.save!(validate: false)

    found = @migration.rows_that_break_the_rules
    assert_equal ["workout logs that repeat a workout on a day"], found.keys
    assert_equal ["user #{@user.id}, Upper on #{Date.current}: workout logs #{first.id}, #{second.id} (all mock data)"],
                 found.values.first

    error = assert_raises(ActiveRecord::MigrationError) { @migration.migrate(:up) }
    assert_match "1 workout logs that repeat a workout on a day", error.message
    assert_match "bin/rails mock:clear", error.message
    # it stopped before its first change
    assert connection.column_exists?(:workout_days, :weekday, null: false)
    assert_not connection.index_exists?(:workout_logs, [:user_id, :workout, :date])
  end

  test "exercise names that differ only in capitals are found" do
    connection = ActiveRecord::Base.connection
    connection.remove_index :exercises, name: "index_exercises_on_shared_name"
    Exercise.create!(name: "Squat")
    Exercise.new(name: "SQUAT").save!(validate: false)

    assert_equal ["shared exercises whose names differ only in capitals"], @migration.rows_that_break_the_rules.keys
  end
end
