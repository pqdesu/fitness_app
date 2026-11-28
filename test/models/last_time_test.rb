require "test_helper"

class LastTimeTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(email: "lifter@example.com", password: "secret123")
    @today = Date.new(2026, 11, 18)
    travel_to Time.zone.local(2026, 11, 18, 12)
    @bench = Exercise.create!(name: "Bench press")
    @push = @user.splits.create!(name: "PPL").workout_days.create!(day: "Push", weekday: 3)
    @planned = @push.workout_exercises.create!(exercise: @bench)
  end

  test "the last log skips a workout with no sets and no cardio rows" do
    @planned.entry_on!(@today - 14).workout_sets.create!(reps_completed: 8, weight_used: 80)
    @planned.entry_on!(@today - 7) # added, nothing done
    empty = WorkoutLog.create!(user: @user, workout_day: @push, date: @today - 3, started_at: Time.current)

    dashboard = Dashboard.new(@user, @today)
    assert_equal @today - 14, dashboard.last_log.date
    assert_not_equal empty, dashboard.last_log
  end

  test "previous_for is the latest entry with sets before the date, of that exercise and user" do
    @planned.entry_on!(@today - 14).workout_sets.create!(reps_completed: 8, weight_used: 80)
    newer = @planned.entry_on!(@today - 7)
    newer.workout_sets.create!(reps_completed: 6, weight_used: 90)
    @planned.entry_on!(@today - 3) # no sets: skipped
    @planned.entry_on!(@today).workout_sets.create!(reps_completed: 5, weight_used: 95) # not before

    assert_equal newer, WorkoutLogExercise.previous_for(@user, @bench.id, before: @today)
    assert_equal newer.workout_log.date, WorkoutLogExercise.previous_for(@user, @bench.id, before: @today - 1).workout_log.date
    assert_nil WorkoutLogExercise.previous_for(@user, @bench.id, before: @today - 14)
    assert_nil WorkoutLogExercise.previous_for(User.create!(email: "x@example.com", password: "secret123"), @bench.id, before: @today)
    assert_nil WorkoutLogExercise.previous_for(@user, nil, before: @today)
  end
end
