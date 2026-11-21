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

  test "the plan is reordered on the split page by dragging, and the workout day follows it" do
    bench, squat, deadlift = @planned
    get split_path(@day.split)
    assert_equal ["Bench press", "Squat", "Deadlift"], css_select("#day-#{@day.id} .row-title").map(&:text)
    # each row is dragged by its handle; dropping it sends where it landed
    assert_select "#day-#{@day.id} ul.list-rows[data-controller=sortable]", 1
    assert_select "#day-#{@day.id} li[data-sortable-url=?] .drag-handle", move_workout_exercise_path(squat), 1
    assert_select "#day-#{@day.id} .drag-handle", 3
    assert_select "#day-#{@day.id} .move-buttons", 0

    patch move_workout_exercise_path(deadlift, to: 1)
    assert_redirected_to split_path(@day.split, anchor: "day-#{@day.id}")
    patch move_workout_exercise_path(bench, to: 3)
    patch move_workout_exercise_path(squat, to: 9) # off the list: nothing moves

    get split_path(@day.split)
    assert_equal ["Deadlift", "Squat", "Bench press"], css_select("#day-#{@day.id} .row-title").map(&:text)
    get workout_day_path(@day)
    assert_equal ["Deadlift", "Squat", "Bench press"], css_select("#day-exercises .row-title").map(&:text)
  end

  test "a logged workout has its own order on its own page; the plan keeps its order" do
    log = @user.workout_logs.create!(workout: "Push", workout_day: @day, date: Date.current)
    bench, squat, deadlift = @planned.map { |planned| log.workout_log_exercises.create!(workout_exercise: planned) }
    get workout_log_path(log)
    assert_equal ["Bench press", "Squat", "Deadlift"], css_select(".entry-card h2").map(&:text)
    # each card is dragged by its handle
    assert_select "[data-controller=sortable] > #entry-#{squat.id}[data-sortable-url=?] .drag-handle", move_workout_log_exercise_path(squat), 1
    # and Move up / Move down stay in each exercise's ⋯ menu; the first has no Move up, the last no Move down
    assert_select "#entry-#{bench.id} .actions-menu form[action=?]", move_workout_log_exercise_path(bench, to: "up"), 0
    assert_select "#entry-#{bench.id} .actions-menu form[action=?]", move_workout_log_exercise_path(bench, to: "down"), text: /Move down/
    assert_select "#entry-#{squat.id} .actions-menu form[action=?]", move_workout_log_exercise_path(squat, to: "up"), text: /Move up/
    assert_select "#entry-#{deadlift.id} .actions-menu form[action=?]", move_workout_log_exercise_path(deadlift, to: "down"), 0

    patch move_workout_log_exercise_path(deadlift, to: 1)
    assert_redirected_to workout_log_path(log, anchor: "entry-#{deadlift.id}")
    patch move_workout_log_exercise_path(bench, to: "down")

    get workout_log_path(log)
    assert_equal ["Deadlift", "Squat", "Bench press"], css_select(".entry-card h2").map(&:text)
    get split_path(@day.split)
    assert_equal ["Bench press", "Squat", "Deadlift"], css_select("#day-#{@day.id} .row-title").map(&:text)
    # the workout day's page shows that workout in its own order
    get workout_day_path(@day, date: Date.current)
    assert_equal ["Deadlift", "Squat", "Bench press"], css_select("#day-exercises .row-title").map(&:text)
  end

  test "a workout day's page lists the workout first, in its order and draggable, then the plan still to do" do
    _bench, squat, deadlift = @planned
    bulgarian = Exercise.create!(name: "Bulgarian split squat", muscle_group: "Legs")
    # Monday 23 November 2026: Push is today's
    travel_to Time.zone.local(2026, 11, 23, 12) do
      date = Date.current
      # nothing done yet: the plan, in its order, with nothing to drag
      get workout_day_path(@day)
      assert_equal ["Bench press", "Squat", "Deadlift"], css_select("#day-exercises .row-title").map(&:text)
      assert_select "#day-exercises .drag-handle", 0

      # Squat trained first, then Bulgarian split squat added to today's workout
      post workout_exercise_workout_sets_path(squat, date:), params: { workout_set: { weight_used: 100, reps_completed: 5 } }
      post workout_day_workout_log_exercises_path(@day, date:), params: { exercise_ids: [bulgarian.id] }
      log = @user.workout_logs.sole
      squat_entry, bulgarian_entry = log.workout_log_exercises.to_a

      get workout_day_path(@day)
      assert_equal ["Squat", "Bulgarian split squat"], css_select("#day-exercises .day-in-workout .row-title").map(&:text)
      assert_equal ["Bench press", "Deadlift"], css_select("#day-exercises .day-to-do .row-title").map(&:text)
      assert_select ".day-in-workout[data-controller=sortable] li[data-sortable-url=?] .drag-handle",
                    move_workout_log_exercise_path(bulgarian_entry, workout_day_id: @day.id, date:), 1
      assert_select ".day-in-workout li[data-sortable-url=?] .drag-handle", move_workout_log_exercise_path(squat_entry, workout_day_id: @day.id, date:), 1
      assert_select ".day-to-do .drag-handle", 0
      # a planned exercise in the workout still opens its page; an added one its workout
      assert_select ".day-in-workout a.row-link[href=?]", workout_exercise_path(squat, date:)
      assert_select ".day-in-workout a.row-link[href=?]", workout_log_path(log, anchor: "entry-#{bulgarian_entry.id}")

      # Bulgarian split squat was done before Squat
      patch move_workout_log_exercise_path(bulgarian_entry, workout_day_id: @day.id, date:, to: 1)
      assert_redirected_to workout_day_path(@day, date:)
      get workout_day_path(@day)
      assert_equal ["Bulgarian split squat", "Squat"], css_select(".day-in-workout .row-title").map(&:text)
      assert_equal ["Bench press", "Deadlift"], css_select(".day-to-do .row-title").map(&:text)

      # the logged workout has the same order; the plan keeps its own
      get workout_log_path(log)
      assert_equal ["Bulgarian split squat", "Squat"], css_select(".entry-card h2").map(&:text)
      get split_path(@day.split)
      assert_equal ["Bench press", "Squat", "Deadlift"], css_select("#day-#{@day.id} .row-title").map(&:text)

      # Deadlift trained next joins the workout, last
      post workout_exercise_workout_sets_path(deadlift, date:), params: { workout_set: { weight_used: 140, reps_completed: 3 } }
      get workout_day_path(@day)
      assert_equal ["Bulgarian split squat", "Squat", "Deadlift"], css_select(".day-in-workout .row-title").map(&:text)
      assert_equal ["Bench press"], css_select(".day-to-do .row-title").map(&:text)
    end
  end

  test "an exercise added to a plan or to a workout goes last" do
    press = Exercise.create!(name: "Overhead press", muscle_group: "Shoulders")
    row = Exercise.create!(name: "Row", muscle_group: "Back")
    patch move_workout_exercise_path(@planned.last, to: 2)
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

    patch move_workout_exercise_path(planned.last, to: 1)
    assert_response :not_found
    sign_in @user # a 404 does not persist the test session
    patch move_workout_log_exercise_path(entries.last, to: 1)
    assert_response :not_found
    assert_equal planned, day.workout_exercises.reload.to_a
    assert_equal entries, log.workout_log_exercises.reload.to_a
  end
end
