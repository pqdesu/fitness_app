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
      assert_select "#day-exercises .day-in-workout .drag-handle", 0
      assert_select "#day-exercises .day-to-do li[data-sortable-into-url] .drag-handle", 3

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
      assert_select ".day-to-do li[data-sortable-into-url] .drag-handle", 2
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

  test "dropping a planned exercise into the workout adds it at that place and logs the workout" do
    bench, squat, deadlift = @planned
    travel_to Time.zone.local(2026, 11, 23, 12) do
      date = Date.current
      assert_difference -> { @user.workout_logs.count }, 1 do
        post workout_day_workout_log_exercises_path(@day, date:, workout_exercise_id: deadlift.id, to: 1)
      end
      assert_redirected_to workout_day_path(@day, date:)
      post workout_day_workout_log_exercises_path(@day, date:, workout_exercise_id: bench.id, to: 1)
      post workout_day_workout_log_exercises_path(@day, date:, workout_exercise_id: squat.id, to: 2)

      get workout_day_path(@day)
      assert_equal ["Bench press", "Squat", "Deadlift"], css_select(".day-in-workout .row-title").map(&:text)
      assert_select ".day-to-do li:not(.day-hint)", 0
      assert_select ".day-to-do .day-hint", "Everything planned is in this workout."
      assert_select ".day-in-workout li.just-moved .row-title", "Squat"
    end
  end

  test "dragging a planned exercise back out of the workout takes it and its sets out, and it is still to do" do
    bench, squat, _deadlift = @planned
    travel_to Time.zone.local(2026, 11, 23, 12) do
      date = Date.current
      post workout_exercise_workout_sets_path(bench, date:), params: { workout_set: { weight_used: 60, reps_completed: 5 } }
      post workout_day_workout_log_exercises_path(@day, date:, workout_exercise_id: squat.id)
      bench_entry = @user.workout_logs.sole.workout_log_exercises.first

      delete workout_log_exercise_path(bench_entry, workout_day_id: @day.id, date:)
      assert_redirected_to workout_day_path(@day, date:)
      get workout_day_path(@day)
      assert_equal ["Squat"], css_select(".day-in-workout .row-title").map(&:text)
      assert_equal ["Bench press", "Deadlift"], css_select(".day-to-do .row-title").map(&:text)
      assert_equal 0, WorkoutSet.count
    end
  end

  test "a workout day's page has two blocks, and each row allows only the drops it should" do
    bench, squat, = @planned
    bulgarian = Exercise.create!(name: "Bulgarian split squat", muscle_group: "Legs")
    travel_to Time.zone.local(2026, 11, 23, 12) do
      date = Date.current
      # nothing in the workout: its block says what to do, and the plan rows can be dragged into it
      get workout_day_path(@day)
      assert_select "#day-exercises .card", 2
      assert_select ".day-in-workout .day-hint", "Drag an exercise here, or open one and add a set."
      assert_select ".day-in-workout[data-sortable-group-value=day]", 1
      assert_select ".day-to-do[data-controller=sortable][data-sortable-group-value=day][data-sortable-sort-value=false]", 1
      assert_select ".day-to-do li .drag-handle", 3
      assert_select ".day-to-do li[data-sortable-into-url=?][data-sortable-into-method=post]",
                    workout_day_workout_log_exercises_path(@day, date:, workout_exercise_id: squat.id), 1
      assert_select ".day-to-do li[data-sortable-url]", 0

      post workout_exercise_workout_sets_path(bench, date:), params: { workout_set: { weight_used: 60, reps_completed: 5 } }
      post workout_day_workout_log_exercises_path(@day, date:, workout_exercise_id: squat.id)
      post workout_day_workout_log_exercises_path(@day, date:), params: { exercise_ids: [bulgarian.id] }
      bench_entry, squat_entry, bulgarian_entry = @user.workout_logs.sole.workout_log_exercises.to_a
      get workout_day_path(@day)
      assert_select ".day-hint", 0
      back = ->(entry) { workout_log_exercise_path(entry, workout_day_id: @day.id, date:) }
      # with sets: asks first
      assert_select ".day-in-workout li[data-sortable-into-url=?][data-sortable-into-method=delete][data-sortable-confirm=?]",
                    back.(bench_entry), "Remove Bench press and its sets from this workout?", 1
      # without sets: no question
      assert_select ".day-in-workout li[data-sortable-into-url=?][data-sortable-into-method=delete]:not([data-sortable-confirm])", back.(squat_entry), 1
      # added while training, not planned: cannot go back to the plan's block
      assert_select ".day-in-workout li[data-sortable-url=?]:not([data-sortable-into-url])",
                    move_workout_log_exercise_path(bulgarian_entry, workout_day_id: @day.id, date:), 1
      assert_select ".day-to-do li", 1

      # a single row can still be dragged out
      [squat_entry, bulgarian_entry].each(&:destroy)
      get workout_day_path(@day)
      assert_select ".day-in-workout li .drag-handle", 1
    end
  end

  test "a workout day still to come shows only the plan, with nothing to drag" do
    travel_to Time.zone.local(2026, 11, 22, 12) do # Sunday: Monday's Push is later this week
      get workout_day_path(@day, date: Date.new(2026, 11, 23))
      assert_response :success
      assert_equal ["Bench press", "Squat", "Deadlift"], css_select(".day-to-do .row-title").map(&:text)
      assert_select "#day-exercises .drag-handle", 0
      assert_select "#day-exercises [data-sortable-into-url]", 0
      assert_select "#day-exercises .day-in-workout", 0
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

  test "rows of a workout day have a plain chevron and the removal in a menu, not a boxed Open link" do
    _bench, squat, = @planned
    extra = Exercise.create!(name: "Stationary bike", muscle_group: "Legs")
    travel_to Time.zone.local(2026, 11, 23, 12) do
      date = Date.current
      post workout_exercise_workout_sets_path(squat, date:), params: { workout_set: { weight_used: 100, reps_completed: 5 } }
      post workout_day_workout_log_exercises_path(@day, date:), params: { exercise_ids: [extra.id] }
      added = @user.workout_logs.sole.workout_log_exercises.find_by!(name: "Stationary bike")

      get workout_day_path(@day)
      assert_select ".day-in-workout a.btn-light[aria-label^=Open], .day-to-do a.btn-light[aria-label^=Open]", 0
      assert_select ".day-in-workout a.row-link .row-chevron", 2
      assert_select ".day-to-do a.row-link .row-chevron", 2
      assert_select ".day-in-workout a.row-link .chip-done", 1
      assert_select ".day-in-workout .actions-menu", 0
      assert_select ".day-in-workout form.button_to[action=?] button[aria-label=?]",
                    workout_log_exercise_path(added, workout_day_id: @day.id, date:), "Remove Stationary bike from this workout"
    end
  end

  test "moving or removing an exercise returns to the very page it was done on, so it stays in place" do
    log = @user.workout_logs.create!(workout: "Push", workout_day: @day, date: Date.current)
    bench, squat, = @planned.map { |planned| log.workout_log_exercises.create!(workout_exercise: planned) }

    # opened from Home: the address keeps ?from=dashboard, so Turbo refreshes the same page (it
    # morphs and keeps the scroll) and the back button has no extra copy of it to step through
    page = workout_log_path(log, from: "dashboard")
    get page
    assert_select "meta[name='turbo-refresh-method'][content='morph']"
    assert_select "meta[name='turbo-refresh-scroll'][content='preserve']"
    patch move_workout_log_exercise_path(squat, to: 1), headers: { "Referer" => "http://www.example.com#{page}" }
    assert_redirected_to page
    assert_response :see_other
    delete workout_log_exercise_path(bench), headers: { "Referer" => "http://www.example.com#{page}" }
    assert_redirected_to page

    # the workout day's page too, with its date
    day_page = workout_day_path(@day, date: Date.current)
    get day_page
    assert_select "meta[name='turbo-refresh-method'][content='morph']"
    assert_select "meta[name='turbo-refresh-scroll'][content='preserve']"
    patch move_workout_log_exercise_path(squat, to: 1, workout_day_id: @day.id, date: Date.current),
          headers: { "Referer" => "http://www.example.com#{day_page}" }
    assert_redirected_to day_page

    # a referer from another site is never followed: back to the page the change was sent from
    patch move_workout_log_exercise_path(squat, to: 1), headers: { "Referer" => "https://elsewhere.example/x" }
    assert_redirected_to workout_log_path(log, anchor: "entry-#{squat.id}")
  end
end
