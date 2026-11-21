require "test_helper"

# Reordering exercises: the plan on the split page, and each logged workout on its own page.
class ReorderFlowTest < FlowTest
  setup do
    @deadlift = Exercise.create!(name: "Deadlift", muscle_group: "Back")
    split = @user.splits.create!(name: "PPL")
    @day = split.workout_days.create!(day: "Push", weekday: 1)
    @planned = [@bench, @squat, @deadlift].map { |exercise| @day.workout_exercises.create!(exercise:) }
    sign_in @user
  end

  test "the plan is reordered on the split page, and the workout day follows it" do
    bench, squat, deadlift = @planned
    get split_path(@day.split)
    assert_equal ["Bench press", "Squat", "Deadlift"], css_select("#day-#{@day.id} .row-title").map(&:text)
    # the first has no up arrow, the last no down arrow
    assert_select "#day-#{@day.id} form[action=?] button[aria-label='Move Bench press up']", move_workout_exercise_path(bench, direction: "up"), 0
    assert_select "#day-#{@day.id} form[action=?] button[aria-label='Move Deadlift down']", move_workout_exercise_path(deadlift, direction: "down"), 0
    assert_select "#day-#{@day.id} form[action=?] button[aria-label='Move Squat up']", move_workout_exercise_path(squat, direction: "up"), 1

    patch move_workout_exercise_path(deadlift, direction: "up")
    assert_redirected_to split_path(@day.split, anchor: "day-#{@day.id}")
    patch move_workout_exercise_path(bench, direction: "down")

    get split_path(@day.split)
    assert_equal ["Deadlift", "Bench press", "Squat"], css_select("#day-#{@day.id} .row-title").map(&:text)
    get workout_day_path(@day)
    assert_equal ["Deadlift", "Bench press", "Squat"], css_select("#day-exercises .row-title").map(&:text)
  end

  test "a logged workout has its own order on its own page; the plan keeps its order" do
    log = @user.workout_logs.create!(workout: "Push", workout_day: @day, date: Date.current)
    bench, squat, deadlift = @planned.map { |planned| log.workout_log_exercises.create!(workout_exercise: planned) }
    get workout_log_path(log)
    assert_equal ["Bench press", "Squat", "Deadlift"], css_select(".entry-card h2").map(&:text)
    # Move up and Move down are in each exercise's ⋯ menu; the first has no Move up, the last no Move down
    assert_select "#entry-#{bench.id} .actions-menu form[action=?]", move_workout_log_exercise_path(bench, direction: "up"), 0
    assert_select "#entry-#{bench.id} .actions-menu form[action=?]", move_workout_log_exercise_path(bench, direction: "down"), text: /Move down/
    assert_select "#entry-#{squat.id} .actions-menu form[action=?]", move_workout_log_exercise_path(squat, direction: "up"), text: /Move up/
    assert_select "#entry-#{deadlift.id} .actions-menu form[action=?]", move_workout_log_exercise_path(deadlift, direction: "down"), 0

    patch move_workout_log_exercise_path(deadlift, direction: "up")
    assert_redirected_to workout_log_path(log, anchor: "entry-#{deadlift.id}")
    patch move_workout_log_exercise_path(deadlift, direction: "up")

    get workout_log_path(log)
    assert_equal ["Deadlift", "Bench press", "Squat"], css_select(".entry-card h2").map(&:text)
    get split_path(@day.split)
    assert_equal ["Bench press", "Squat", "Deadlift"], css_select("#day-#{@day.id} .row-title").map(&:text)
    get workout_day_path(@day, date: Date.current)
    assert_equal ["Bench press", "Squat", "Deadlift"], css_select("#day-exercises .row-title").map(&:text)
  end

  test "an exercise added to a plan or to a workout goes last" do
    press = Exercise.create!(name: "Overhead press", muscle_group: "Shoulders")
    row = Exercise.create!(name: "Row", muscle_group: "Back")
    patch move_workout_exercise_path(@planned.last, direction: "up")
    post workout_day_workout_exercises_path(@day), params: { exercise_ids: [press.id] }
    get split_path(@day.split)
    assert_equal ["Bench press", "Deadlift", "Squat", "Overhead press"], css_select("#day-#{@day.id} .row-title").map(&:text)

    # Squat and Bench press join the workout as their first sets are added, then Row from the picker
    [@planned[1], @planned[0]].each do |planned|
      post workout_exercise_workout_sets_path(planned, date: Date.current), params: { workout_set: { weight_used: 60, reps_completed: 5 } }
    end
    log = @user.workout_logs.sole
    post workout_log_workout_log_exercises_path(log), params: { exercise_ids: [row.id] }
    get workout_log_path(log)
    assert_equal ["Squat", "Bench press", "Row"], css_select(".entry-card h2").map(&:text)
  end

  test "another user's exercises cannot be moved" do
    day = @admin.splits.create!(name: "Not mine").workout_days.create!(day: "Push", weekday: 1)
    planned = [@bench, @squat].map { |exercise| day.workout_exercises.create!(exercise:) }
    log = @admin.workout_logs.create!(workout: "Push", workout_day: day, date: Date.current)
    entries = planned.map { |row| log.workout_log_exercises.create!(workout_exercise: row) }

    patch move_workout_exercise_path(planned.last, direction: "up")
    assert_response :not_found
    sign_in @user # a 404 does not persist the test session
    patch move_workout_log_exercise_path(entries.last, direction: "up")
    assert_response :not_found
    assert_equal planned, day.workout_exercises.reload.to_a
    assert_equal entries, log.workout_log_exercises.reload.to_a
  end
end
