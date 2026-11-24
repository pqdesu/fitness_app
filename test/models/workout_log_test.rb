require "test_helper"

class WorkoutLogTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(email: "lifter@example.com", password: "secret123")
    @split = @user.splits.create!(name: "PPL")
    @day = @split.workout_days.create!(day: "Push", weekday: 1)
  end

  test "a log takes its user and workout from the day it is logged from" do
    log = @day.workout_logs.create!(date: Date.current)
    assert_equal [@user, "Push"], [log.user, log.workout]

    # renaming the day later does not rewrite what was done
    @day.update!(day: "Upper")
    assert_equal "Push", log.reload.workout
  end

  test "logged workouts stay when their day or split is deleted" do
    log = @day.workout_logs.create!(date: Date.current)
    planned = @day.workout_exercises.create!(name: "Bench press")
    entry = log.workout_log_exercises.create!(workout_exercise: planned)
    entry.workout_sets.create!(reps_completed: 8, weight_used: 60)

    @split.destroy
    log.reload
    assert_nil log.workout_day
    assert_equal [@user, "Push"], [log.user, log.workout]
    assert_equal [log], @user.workout_logs.to_a
    assert_equal ["Bench press"], log.workout_log_exercises.pluck(:name)
    assert_equal 1, entry.workout_sets.count

    # deleting the account still removes everything
    @user.destroy
    assert_equal 0, WorkoutLog.count
    assert_equal 0, WorkoutSet.count
  end

  test "a workout logged on a weekday its split plans nothing for is marked as a rest day" do
    monday = @day.workout_logs.create!(date: Date.new(2026, 11, 16))
    tuesday = @day.workout_logs.create!(date: Date.new(2026, 11, 17))

    assert_not monday.rest_day?
    assert tuesday.rest_day?
    # the split itself is not changed
    assert_equal [1], @split.workout_days.reload.map(&:weekday)

    # adding a Tuesday workout to the split later does not rewrite what was done
    @split.workout_days.create!(day: "Pull", weekday: 2)
    assert tuesday.reload.rest_day?
  end

  test "a workout's date is not after today nor before 2000" do
    travel_to Time.zone.local(2026, 11, 17, 12) do
      assert @day.workout_logs.build(date: Date.new(2026, 11, 17)).valid?
      assert @day.workout_logs.build(date: WorkoutLog::EARLIEST_DATE).valid?

      tomorrow = @day.workout_logs.build(date: Date.new(2026, 11, 18))
      assert_not tomorrow.valid?
      assert_includes tomorrow.errors[:date], "can't be in the future"
      [Date.new(1999, 12, 31), Date.new(1, 1, 1)].each do |date|
        old = @day.workout_logs.build(date:)
        assert_not old.valid?, date.to_s
        assert_includes old.errors[:date], "can't be before 2000"
      end

      log = @day.workout_logs.create!(date: Date.new(2026, 11, 16))
      ["2200-05-05", "99999-01-01", "0001-01-01"].each { |date| assert_not log.update(date:), date }
      assert_equal Date.new(2026, 11, 16), log.reload.date
    end
  end

  test "a log counts as logged once an exercise was added or its timer was started" do
    log = @day.workout_logs.create!(date: Date.current)
    assert_not log.logged?, "a log with nothing in it is not a workout done"

    log.workout_log_exercises.create!(name: "Bench press")
    assert log.reload.logged?

    timed = @day.workout_logs.create!(date: Date.current - 7, started_at: Time.current)
    assert timed.logged?
  end
end
