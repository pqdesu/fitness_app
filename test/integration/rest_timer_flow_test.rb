require "test_helper"

# The rest timer between sets: Start rest after a set, Stop before the next one, and the rest is
# saved on that next set. Earlier days have no timer: their rest is typed in whole minutes ("~3 min").
class RestTimerFlowTest < FlowTest
  setup do
    split = @user.splits.create!(name: "PPL")
    @day = split.workout_days.create!(day: "Push", weekday: Date.current.wday)
    @planned = @day.workout_exercises.create!(exercise: @bench)
    sign_in @user
  end

  test "Start rest, then Stop, and the next set saves the rest to the second" do
    post workout_exercise_workout_sets_path(@planned, date: Date.current), params: { workout_set: { weight_used: 80, reps_completed: 8 } }
    entry = @user.workout_log_exercises.last

    travel_to Time.current.change(usec: 0) do
      post workout_log_exercise_rest_path(entry, workout_exercise_id: @planned.id, date: Date.current)
      assert_redirected_to workout_exercise_path(@planned, date: Date.current)
      travel 135.seconds
      patch workout_log_exercise_rest_path(entry, workout_exercise_id: @planned.id, date: Date.current)
      travel 60.seconds # the set itself, not rest
      post workout_exercise_workout_sets_path(@planned, date: Date.current), params: { workout_set: { weight_used: 80, reps_completed: 7 } }
    end

    first, second = entry.workout_sets.order(:set_number)
    assert_nil first.rest_seconds
    assert_equal 135, second.rest_seconds
    assert_not second.rest_approx
    # the timer is done: the set after that has no rest unless the timer runs again
    post workout_exercise_workout_sets_path(@planned, date: Date.current), params: { workout_set: { weight_used: 80, reps_completed: 6 } }
    assert_nil entry.workout_sets.order(:set_number).last.rest_seconds
  end

  test "No rest throws the running timer away: the next set saves no rest" do
    post workout_exercise_workout_sets_path(@planned, date: Date.current), params: { workout_set: { weight_used: 80, reps_completed: 8 } }
    entry = @user.workout_log_exercises.last
    post workout_log_exercise_rest_path(entry)
    assert_redirected_to workout_log_path(entry.workout_log_id, anchor: "entry-#{entry.id}")
    travel 90.seconds do
      delete workout_log_exercise_rest_path(entry)
      post workout_exercise_workout_sets_path(@planned, date: Date.current), params: { workout_set: { weight_used: 80, reps_completed: 7 } }
    end
    assert_nil entry.workout_sets.order(:set_number).last.rest_seconds
  end

  test "Start rest shows after a set on today's workout, the clock and Stop while it runs, the rest once stopped" do
    today = Date.current
    get workout_exercise_path(@planned, date: today)
    assert_select ".rest-timer", 0 # no set yet: nothing to rest from

    post workout_exercise_workout_sets_path(@planned, date: today), params: { workout_set: { weight_used: 80, reps_completed: 8 } }
    entry = @user.workout_log_exercises.last
    rest_path = workout_log_exercise_rest_path(entry, workout_exercise_id: @planned.id, date: today)
    get workout_exercise_path(@planned, date: today)
    assert_select ".rest-timer form[action=?]", rest_path, text: /Start rest/
    assert_select ".set-form[data-rest-url]", 0

    travel_to Time.current.change(usec: 0) do
      post rest_path
      get workout_exercise_path(@planned, date: today)
      assert_select ".rest-timer [data-controller=timer][data-timer-start-value=?]", Time.current.iso8601
      assert_select ".rest-timer form[action=?] input[name=_method][value=patch]", rest_path
      assert_select ".rest-timer", text: /Start rest/, count: 0
      # Add set asks first while it runs (rest_alert_controller.js), and so does leaving the page
      assert_select ".set-form[data-rest-url=?][data-rest-started=?]", workout_log_exercise_rest_path(entry), Time.current.iso8601
      assert_select ".rest-clock[data-timer-format-value=short]", text: "0:00"
      assert_select "[data-controller=rest-alert]", 1

      travel 135.seconds
      get workout_exercise_path(@planned, date: today)
      assert_select ".rest-clock[data-timer-format-value=short]", text: "2:15"
      patch rest_path
      get workout_exercise_path(@planned, date: today)
      assert_select ".rest-timer", text: /Rest 2 min 15 s/
      assert_select ".rest-timer [data-controller=timer]", 0
      assert_select ".set-form[data-rest-url]", 0
    end

    # No rest: back to Start rest
    delete rest_path
    get workout_exercise_path(@planned, date: today)
    assert_select ".rest-timer form[action=?]", rest_path, text: /Start rest/

    # the logged workout has Start rest on each exercise of today
    get workout_log_path(entry.workout_log)
    assert_select "#entry-#{entry.id} .rest-timer form[action=?]", workout_log_exercise_rest_path(entry), text: /Start rest/
  end

  test "an earlier day has no rest timer" do
    yesterday = Date.current - 1
    @day.update!(weekday: yesterday.wday)
    post workout_exercise_workout_sets_path(@planned, date: yesterday), params: { workout_set: { weight_used: 80, reps_completed: 8 } }
    entry = @user.workout_log_exercises.last
    get workout_exercise_path(@planned, date: yesterday)
    assert_select ".order-badge", "1"
    assert_select ".rest-timer", 0
    get workout_log_path(entry.workout_log)
    assert_select ".rest-timer", 0
  end

  test "an earlier day's set takes its rest in whole minutes, shown as about that; today's sets are measured" do
    get workout_exercise_path(@planned, date: Date.current)
    assert_select ".set-form select[name=?]", "workout_set[rest_minutes]", 0

    yesterday = Date.current - 1
    @day.update!(weekday: yesterday.wday)
    get workout_exercise_path(@planned, date: yesterday)
    assert_select ".set-form select[name=?] option[value='']", "workout_set[rest_minutes]", text: "–"
    assert_select ".set-form select[name=?] option[selected]", "workout_set[rest_minutes]", 0
    post workout_exercise_workout_sets_path(@planned, date: yesterday), params: { workout_set: { weight_used: 80, reps_completed: 8, rest_minutes: "" } }
    post workout_exercise_workout_sets_path(@planned, date: yesterday), params: { workout_set: { weight_used: 80, reps_completed: 7, rest_minutes: "3" } }
    first, second = @user.workout_log_exercises.last.workout_sets.order(:set_number)
    assert_nil first.rest_seconds
    assert_equal [180, true], [second.rest_seconds, second.rest_approx]

    # the rest shows above its set, on the exercise page and on the logged workout
    get workout_exercise_path(@planned, date: yesterday)
    assert_select ".set-rest", 1
    assert_select ".set-rest", "Rest ~3 min"
    get workout_log_path(second.workout_log_exercise.workout_log)
    assert_select ".set-rest", "Rest ~3 min"
    # the logged workout of an earlier day takes the minutes too
    assert_select ".set-form select[name=?]", "workout_set[rest_minutes]", 1
  end

  test "a measured rest shows to the second" do
    post workout_exercise_workout_sets_path(@planned, date: Date.current), params: { workout_set: { weight_used: 80, reps_completed: 8 } }
    entry = @user.workout_log_exercises.last
    entry.workout_sets.create!(weight_used: 80, reps_completed: 7, rest_seconds: 135)
    get workout_exercise_path(@planned, date: Date.current)
    assert_select ".set-rest", "Rest 2 min 15 s"
  end

  test "a set's Edit changes its rest: minutes and seconds when measured, about so many minutes otherwise" do
    post workout_exercise_workout_sets_path(@planned, date: Date.current), params: { workout_set: { weight_used: 80, reps_completed: 8 } }
    entry = @user.workout_log_exercises.last
    measured = entry.workout_sets.create!(weight_used: 80, reps_completed: 7, rest_seconds: 135)
    typed = entry.workout_sets.create!(weight_used: 80, reps_completed: 6, rest_seconds: 180, rest_approx: true)
    page = workout_exercise_path(@planned, date: Date.current)

    get page
    assert_select "select[form=edit_set_#{measured.id}][name=?] option[selected]", "workout_set[rest_minutes]", text: "2"
    assert_select "select[form=edit_set_#{measured.id}][name=?] option[selected]", "workout_set[rest_secs]", text: "15"
    assert_select "select[form=edit_set_#{typed.id}][name=?] option[selected]", "workout_set[rest_minutes]", text: "~3"
    assert_select "select[form=edit_set_#{typed.id}][name=?]", "workout_set[rest_secs]", 0

    patch workout_set_path(measured, workout_exercise_id: @planned.id, date: Date.current), params: { workout_set: { rest_minutes: "1", rest_secs: "30" } }
    assert_redirected_to page
    assert_equal [90, false], [measured.reload.rest_seconds, measured.rest_approx]
    patch workout_set_path(typed), params: { workout_set: { rest_minutes: "4" } }
    assert_equal [240, true], [typed.reload.rest_seconds, typed.rest_approx]
    # a note saved without the picker keeps the rest; "–" takes it off
    patch workout_set_path(measured), params: { workout_set: { notes: "Felt strong" } }
    assert_equal 90, measured.reload.rest_seconds
    patch workout_set_path(typed), params: { workout_set: { rest_minutes: "" } }
    assert_nil typed.reload.rest_seconds
  end

  test "another user's rest timer is not found" do
    log = @admin.workout_logs.create!(workout: "Push", date: Date.current)
    theirs = log.workout_log_exercises.create!(exercise: @squat)
    [:post, :patch, :delete].each do |verb|
      send(verb, workout_log_exercise_rest_path(theirs))
      assert_response :not_found
      sign_in @user # a 404 drops the test session
    end
    assert_nil theirs.reload.rest_started_at
  end

  test "the rest clock is m:ss under an hour and h:mm:ss from one" do
    helper = Object.new.extend(ApplicationHelper)
    assert_equal ["0:05", "2:15", "59:59", "1:00:00"], [5, 135, 3599, 3600].map { |s| helper.short_clock(s) }
  end
end
