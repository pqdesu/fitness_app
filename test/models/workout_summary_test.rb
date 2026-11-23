require "test_helper"

class WorkoutSummaryTest < ActiveSupport::TestCase
  setup do
    # A workout is never logged after today; the dates below are of the week of November 16.
    travel_to Time.zone.local(2026, 11, 20, 12)
    user = User.create!(email: "lifter@example.com", password: "secret123")
    split = user.splits.create!(name: "PPL")
    @push = split.workout_days.create!(day: "Push", weekday: 1)
    @pull = split.workout_days.create!(day: "Pull", weekday: 3)
  end

  def log_with(day, date, lifts)
    log = day.workout_logs.create!(date: date)
    lifts.each do |name, sets|
      entry = log.workout_log_exercises.create!(name: name)
      sets.each { |reps, weight| entry.workout_sets.create!(reps_completed: reps, weight_used: weight) }
    end
    WorkoutLog.includes(workout_log_exercises: :workout_sets).find(log.id)
  end

  test "totals over several workouts" do
    monday = log_with(@push, Date.new(2026, 11, 16), { "Bench press" => [[8, 60], [6, 80]], "Dips" => [[12, nil]] })
    wednesday = log_with(@pull, Date.new(2026, 11, 18), { "Bench press" => [[5, 100]], "Row" => [[10, 70]] })
    summary = WorkoutSummary.new([monday, wednesday])

    assert_equal 2, summary.workouts
    assert_equal 3, summary.exercises, "an exercise done twice counts once"
    assert_equal 5, summary.sets
    assert_equal 100, summary.top_weight
    assert_equal 3, summary.sets_in(monday)
  end

  test "exercises without sets are not counted, and bodyweight sets have no top weight" do
    log = log_with(@push, Date.new(2026, 11, 16), { "Dips" => [[12, nil]], "Empty lift" => [] })
    summary = WorkoutSummary.new(log)

    assert_equal 1, summary.exercises
    assert_equal 1, summary.sets
    assert_nil summary.top_weight
  end

  test "a bodyweight exercise's added weight is not a top weight" do
    log = @push.workout_logs.create!(date: Date.new(2026, 11, 16))
    dips = log.workout_log_exercises.create!(name: "Weighted dips", equipment: "bodyweight")
    dips.workout_sets.create!(reps_completed: 8, weight_used: 20)
    dips.workout_sets.create!(reps_completed: 6, weight_used: -10)
    log.workout_log_exercises.create!(name: "Curl").workout_sets.create!(reps_completed: 10, weight_used: 15)
    summary = WorkoutSummary.new(WorkoutLog.includes(workout_log_exercises: :workout_sets).find(log.id))

    assert_equal 15, summary.top_weight
    assert_equal 3, summary.sets
  end

  test "no workouts" do
    summary = WorkoutSummary.new([])

    assert_equal [0, 0, 0, nil], [summary.workouts, summary.exercises, summary.sets, summary.top_weight]
  end
end
