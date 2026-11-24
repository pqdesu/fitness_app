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

  test "the month's totals leave out other months, and workouts outside a split are grouped last" do
    split = @user.splits.create!(name: "PPL")
    push = split.workout_days.create!(day: "Push", weekday: 1)
    bench = push.workout_exercises.create!(exercise: Exercise.create!(name: "Bench press"))
    bench.entry_on!(@today - 2).workout_sets.create!(reps_completed: 8, weight_used: 80)
    bench.entry_on!(@today - 20).workout_sets.create!(reps_completed: 8, weight_used: 90) # October
    extra = @user.workout_logs.create!(workout: "Pull", date: @today)
    extra.workout_log_exercises.create!(name: "Row").workout_sets.create!(reps_completed: 10, weight_used: 50)

    dashboard = Dashboard.new(@user, @today)
    assert_equal [2, 2], [dashboard.month_summary.workouts, dashboard.month_summary.sets]
    assert_equal [split, nil], dashboard.month_by_split.map(&:first)
    assert_equal [["Bench press", 1, 80, 0], ["Row", 1, 50, 0]], dashboard.month_summary.by_exercise
  end

  test "each day is planned, missed or extra, by the plan of its week" do
    split = @user.splits.create!(name: "PPL")
    push = split.workout_days.create!(day: "Push", weekday: 1)
    pull = split.workout_days.create!(day: "Pull", weekday: 3)
    legs = split.workout_days.create!(day: "Legs", weekday: 5)
    push.workout_logs.create!(date: Date.new(2026, 11, 9)).workout_log_exercises.create!(name: "Bench").workout_sets.create!(reps_completed: 8)
    legs.workout_logs.create!(date: Date.new(2026, 11, 13)) # nothing in it
    push.workout_logs.create!(date: Date.new(2026, 11, 16)).workout_log_exercises.create!(name: "Bench").workout_sets.create!(reps_completed: 8)
    @user.workout_logs.create!(workout: "Pull", date: Date.new(2026, 11, 14)).workout_log_exercises.create!(name: "Row")

    states = Dashboard.new(@user, @today).calendar_states
    assert_equal :planned, states[Date.new(2026, 11, 9)], "a day of the plan that was trained"
    assert_equal :missed, states[Date.new(2026, 11, 11)], "a day of the plan that passed with nothing"
    assert_equal :missed, states[Date.new(2026, 11, 13)], "an empty log is nothing"
    assert_equal :extra, states[Date.new(2026, 11, 14)], "trained on a day the plan did not have"
    assert_equal :planned, states[Date.new(2026, 11, 16)]
    assert_equal :planned, states[@today], "today is planned, not missed, with the day still to train"
    assert_equal :planned, states[Date.new(2026, 11, 20)], "days to come stay planned"
    assert_nil states[Date.new(2026, 11, 2)], "nothing is missed before the first workout logged"
    assert_nil states[Date.new(2026, 11, 15)], "a day off the plan with nothing logged"

    assert_equal :planned, Dashboard.new(@user, @today).week_states[1], "the week is read by weekday"

    # a workout moved for the week is on its new day, and the day it left is off the plan
    split.move_for_week!(pull, 4, @today)
    week = Dashboard.new(@user, @today).week_states
    assert_equal :planned, week[4]
    assert_nil week[3]
  end
end
