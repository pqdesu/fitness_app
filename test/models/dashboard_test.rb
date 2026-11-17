require "test_helper"

class DashboardTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(email: "lifter@example.com", password: "secret123")
    @today = Date.new(2026, 11, 18) # a Wednesday
    # A workout is never logged after today, so the clock is on that Wednesday too.
    travel_to Time.zone.local(2026, 11, 18, 12)
  end

  test "without a split there is nothing planned, and the calendar still covers the month" do
    dashboard = Dashboard.new(@user, @today)
    assert_nil dashboard.split
    assert_empty dashboard.days
    assert_empty dashboard.week_plan
    assert_nil dashboard.today_workout
    assert_nil dashboard.today_log
    assert_nil dashboard.last_log
    assert_not dashboard.week_moved?
    assert_empty dashboard.recent_logs

    assert_equal Date.new(2026, 11, 1), dashboard.calendar_weeks.first.first
    assert_equal Date.new(2026, 12, 5), dashboard.calendar_weeks.last.last
    assert(dashboard.calendar_weeks.all? { |week| week.size == 7 && week.first.sunday? })
    assert_equal (Date.new(2026, 11, 15)..Date.new(2026, 11, 21)).to_a, dashboard.week_dates
  end

  test "today's workout, its sessions, and what is left to move this week" do
    split = @user.splits.create!(name: "PPL")
    push = split.workout_days.create!(day: "Push", weekday: 1)
    legs = split.workout_days.create!(day: "Legs", weekday: 3)
    bench = push.workout_exercises.create!(exercise: Exercise.create!(name: "Bench press"))
    squat = legs.workout_exercises.create!(exercise: Exercise.create!(name: "Squat"))
    bench.entry_on!(@today - 2).workout_sets.create!(reps_completed: 8, weight_used: 80)
    squat.entry_on!(@today - 7).workout_sets.create!(reps_completed: 5, weight_used: 100)
    squat.entry_on!(@today).workout_sets.create!(reps_completed: 5, weight_used: 110)

    dashboard = Dashboard.new(@user, @today)
    assert_equal split, dashboard.split
    assert_equal [push, legs], dashboard.days
    assert_equal({ 1 => push, 3 => legs }, dashboard.week_plan)
    assert_equal legs, dashboard.today_workout
    assert_equal @today, dashboard.today_log.date
    assert_equal @today - 7, dashboard.last_log.date
    assert_equal ["Squat"], dashboard.today_lifts.map(&:name)
    assert_equal 1, dashboard.today_summary.sets
    assert_equal 2, dashboard.week_summary.workouts
    assert_equal BigDecimal("110"), dashboard.week_summary.top_weight

    # both workouts of the week are trained, so nothing is left to move
    assert_empty dashboard.movable_days
    assert_equal({ push.id => 1, legs.id => 1 }, dashboard.exercise_counts)
    assert_equal WorkoutDay::NAMES - %w[Push Legs Lower], dashboard.other_workouts
    assert_equal({ "Push" => { 1 => push }, "Legs" => { 3 => legs } }, dashboard.rest_day_choices)
    assert_equal [@today, @today - 2, @today - 7], dashboard.recent_logs.map(&:date)
    assert_equal [3, 3], [dashboard.logs_count, dashboard.sets_count]
    assert_equal [@today - 2, @today], dashboard.calendar_logs.keys.select { |date| date >= @today - 2 }.sort
  end
end
