require "test_helper"

# The workout timer: started by hand or on its own, paused, resumed and stopped by hand, and shown with the workout.
class TimerFlowTest < FlowTest
  setup do
    split = @user.splits.create!(name: "PPL")
    @day = split.workout_days.create!(day: "Push", weekday: Date.current.wday)
    @bench_plan = @day.workout_exercises.create!(exercise: @bench)
    sign_in @user
  end

  test "the timer starts, pauses and resumes; the workout shows its time recorded and its time paused" do
    get workout_day_path(@day)
    assert_select ".timer-card form[action=?]", workout_day_timer_path(@day, date: Date.current), text: /Start timer/

    start = Time.current.change(hour: 18, min: 2)
    travel_to(start) { post workout_day_timer_path(@day, date: Date.current) }
    log = @user.workout_logs.sole
    assert_equal [start.to_i, nil, 0], [log.started_at.to_i, log.ended_at, log.paused_seconds]
    assert_empty log.workout_log_exercises

    # running: the clock and Pause, on the day's page and the workout's page; Start again changes nothing
    travel_to(start + 5.minutes) { post workout_day_timer_path(@day, date: Date.current) }
    assert_equal start.to_i, log.reload.started_at.to_i
    get workout_day_path(@day)
    assert_select ".timer-clock[data-timer-start-value=?]", log.started_at.iso8601
    get workout_log_path(log)
    assert_select ".timer-card form[action=?]", pause_workout_log_timer_path(log), text: /Pause/
    assert_select ".timer-card form[action=?][data-turbo-confirm]", workout_log_timer_path(log), text: /Stop/

    # paused at 6:30 PM: the time so far stands still; Resume carries on, Stop is still there
    travel_to(start + 28.minutes) do
      post pause_workout_log_timer_path(log)
      get workout_day_path(@day)
    end
    assert_equal (start + 28.minutes).to_i, log.reload.paused_at.to_i
    assert_nil log.ended_at
    assert_select ".timer-clock", text: "0:28:00"
    assert_select ".timer-card", text: /since 6:30 PM/
    assert_select ".timer-card form[action=?]", workout_log_timer_path(log), text: /Resume/
    assert_select ".timer-card form[action=?]", workout_log_timer_path(log), text: /Stop/
    # resumed at 6:40 PM: those 10 minutes are paused time, not recorded
    travel_to(start + 38.minutes) { post workout_day_timer_path(@day, date: Date.current) }
    assert_equal [nil, 600], [log.reload.paused_at, log.paused_seconds]
    get workout_log_path(log)
    assert_select ".timer-clock[data-timer-offset-value='-600']"

    # stopped at 7:15 PM: 73 minutes from start to end, 63 of them recorded; it cannot resume
    travel_to(start + 73.minutes) { delete workout_log_timer_path(log) }
    assert_equal (start + 73.minutes).to_i, log.reload.ended_at.to_i
    post workout_log_timer_path(log)
    assert_match "was stopped", flash[:alert]
    get workout_log_path(log)
    assert_select ".timer-card form", 0
    assert_select ".timer-card", text: /6:02 PM ~ 7:15 PM · 1 h 3 min · paused 10 min/
    get workout_logs_path
    assert_select ".history-counts", text: /6:02 PM ~ 7:15 PM · 1 h 3 min · paused 10 min/
    assert_select ".chip-day", 0
  end

  test "stopped while paused, the workout ends at its pause" do
    start = Time.current.change(hour: 18, min: 2)
    travel_to(start) { post workout_day_timer_path(@day, date: Date.current) }
    log = @user.workout_logs.sole
    travel_to(start + 40.minutes) { post pause_workout_log_timer_path(log) }
    travel_to(start + 55.minutes) { delete workout_log_timer_path(log) }
    assert_equal [(start + 40.minutes).to_i, nil, 0], [log.reload.ended_at.to_i, log.paused_at, log.paused_seconds]
    get workout_log_path(log)
    assert_select ".timer-card", text: /6:02 PM ~ 6:42 PM · 40 min/
    assert_select ".timer-card", text: /paused/, count: 0

    # a pause can only follow a running timer
    post pause_workout_log_timer_path(log)
    assert_match "not running", flash[:alert]
  end

  test "with the automatic timer, opening today's workout presses Start; off, the user does" do
    start_path = workout_day_timer_path(@day, date: Date.current)
    get workout_day_path(@day)
    assert_select ".timer-card form[action=?]", start_path
    assert_select ".timer-card form[data-controller='auto-submit']", 0
    post workout_exercise_workout_sets_path(@bench_plan), params: { workout_set: { weight_used: 60, reps_completed: 8 } }
    assert_nil @user.workout_logs.sole.started_at
    @user.workout_logs.destroy_all

    put user_registration_path, params: { user: { timer_auto_start: "1", current_password: "secret123" } }
    assert @user.reload.timer_auto_start?
    get workout_day_path(@day)
    assert_select ".timer-card form[data-controller='auto-submit'][action=?]", start_path
    # an earlier day of the week opened to fill it in starts nothing
    get workout_day_path(@day, date: Date.yesterday)
    assert_select ".timer-card", 0

    # what the page sends: the workout is logged with no exercises, its timer running
    post workout_day_timer_path(@day, date: Date.current)
    log = @user.workout_logs.sole
    assert_not_nil log.started_at
    assert_empty log.workout_log_exercises
    # opened again, it is not started over
    assert_no_changes -> { log.reload.started_at } do
      travel(10.minutes) { post workout_day_timer_path(@day, date: Date.current) }
    end

    # a workout logged without opening its page (a set added straight away) starts on its own too
    log.destroy!
    post workout_exercise_workout_sets_path(@bench_plan), params: { workout_set: { weight_used: 60, reps_completed: 8 } }
    assert_not_nil @user.workout_logs.sole.started_at
  end

  test "the automatic timer does not start a workout the split cannot log today" do
    @user.update!(timer_auto_start: true)
    other = @day.split.workout_days.create!(day: "Pull", weekday: (Date.current.wday + 1) % 7)
    @day.workout_logs.create!(date: Date.current)
    get workout_day_path(other, date: Date.current)
    assert_select ".timer-card form[data-controller='auto-submit']", 0
  end

  test "a timer goes past midnight: it pauses, resumes and stops on the workout's own day, to the second" do
    start = Time.current.change(hour: 23, min: 16)
    travel_to(start) { post workout_day_timer_path(@day, date: start.to_date) }
    log = @user.workout_logs.sole
    travel_to(start + 34.minutes) { post pause_workout_log_timer_path(log) }

    # 12:10 AM, the next day: the pause shows its date, and Resume still carries on
    travel_to(start + 54.minutes) do
      get workout_log_path(log)
      # the time paused counts up from the pause: 20 minutes so far
      assert_select ".timer-paused[data-timer-start-value=?][data-timer-offset-value='0']", log.reload.paused_at.iso8601, text: "0:20:00"
      assert_select ".timer-card", text: /since 11:50 PM/
      assert_select ".timer-card .chip-day", text: start.strftime("%d/%m")
      post workout_log_timer_path(log)
    end
    assert_equal [nil, 20 * 60], [log.reload.paused_at, log.paused_seconds]

    travel_to(start + 104.minutes + 7.seconds) do
      get workout_day_path(@day, date: start.to_date)
      assert_select ".timer-card form[action=?]", workout_log_timer_path(log), text: /Stop/
      delete workout_log_timer_path(log)
      get workout_log_path(log)
    end
    assert_select ".timer-card form", 0
    assert_equal start.to_date, log.reload.date
    # past midnight the workout stays on its day, each time shows its date, and nothing is rounded:
    # 1 h 44 min 7 s from start to end, less 20 min paused
    days = [start, start + 1.day].map { |time| time.strftime("%d/%m") }
    assert_select ".timer-card", text: %r{11:16 PM #{days[0]} ~ 1:00 AM #{days[1]} · 1 h 24 min 7 s · paused 20 min}
    assert_equal days, css_select(".timer-card .chip-day").map(&:text)
  end

  test "only today's workout starts a timer; once started it pauses, resumes or stops whenever; only the user's own" do
    yesterday = @user.workout_logs.create!(workout: "Pull", date: Date.yesterday)
    post workout_log_timer_path(yesterday)
    assert_match "only starts on today's workout", flash[:alert]
    delete workout_log_timer_path(yesterday)
    assert_match "not running", flash[:alert]
    assert_nil yesterday.reload.started_at

    # left running since yesterday, it still counts, pauses, resumes and stops
    yesterday.update!(started_at: 1.day.ago)
    get workout_log_path(yesterday)
    assert_select ".timer-card form[action=?]", pause_workout_log_timer_path(yesterday), text: /Pause/
    post pause_workout_log_timer_path(yesterday)
    assert_not_nil yesterday.reload.paused_at
    get workout_log_path(yesterday)
    assert_select ".timer-card form[action=?]", workout_log_timer_path(yesterday), text: /Resume/
    post workout_log_timer_path(yesterday)
    assert_match "resumed", flash[:notice]
    assert_nil yesterday.reload.paused_at
    delete workout_log_timer_path(yesterday)
    assert_not_nil yesterday.reload.ended_at

    others = @admin.workout_logs.create!(workout: "Push", date: Date.current)
    post workout_log_timer_path(others)
    assert_response :not_found
  end

  test "a timer left running is corrected from History: the finish is set in hours and minutes, seconds at 0" do
    travel_to(Time.current.change(hour: 12)) do
      day_before = Date.yesterday
      log = @user.workout_logs.create!(workout: "Pull", date: day_before, started_at: day_before.in_time_zone.change(hour: 18, min: 2, sec: 37))
      get workout_logs_path
      assert_select ".history-counts a.timer-edit[href=?]", edit_workout_log_timer_path(log), count: 2
      get edit_workout_log_timer_path(log)
      assert_select "input[type=time][name=finished_at][value=?]", "12:00"

      patch workout_log_timer_path(log), params: { finished_at: "19:15" }
      assert_redirected_to workout_logs_path
      assert_equal day_before.in_time_zone.change(hour: 19, min: 15), log.reload.ended_at
      get workout_logs_path
      assert_select ".history-counts", text: /6:02 PM ~ 7:15 PM · 1 h 12 min 23 s/

      # paused and left so: it stops at the time chosen, and the time paused before stays out
      log.update_columns(ended_at: nil, paused_at: day_before.in_time_zone.change(hour: 21), paused_seconds: 600)
      patch workout_log_timer_path(log), params: { finished_at: "19:30" }
      assert_equal [day_before.in_time_zone.change(hour: 19, min: 30), nil], [log.reload.ended_at, log.paused_at]
      get workout_logs_path
      assert_select ".history-counts", text: /6:02 PM ~ 7:30 PM · 1 h 17 min 23 s · paused 10 min/

      # past midnight: a time earlier than the start is the next day
      log.update_columns(started_at: day_before.in_time_zone.change(hour: 23, min: 16), paused_seconds: 0)
      patch workout_log_timer_path(log), params: { finished_at: "01:00" }
      assert_equal Date.current.in_time_zone.change(hour: 1), log.reload.ended_at

      # refused: not a clock time, a time still to come, less time than was paused
      patch workout_log_timer_path(log), params: { finished_at: "25:00" }
      assert_response :unprocessable_content
      assert_select ".alert-danger", text: /Choose the time it finished/
      patch workout_log_timer_path(log), params: { finished_at: "13:00" }
      assert_select ".alert-danger", text: /can't be in the future/
      log.update_columns(paused_seconds: 3 * 3600)
      patch workout_log_timer_path(log), params: { finished_at: "01:00" }
      assert_select ".alert-danger", text: /less time than was paused/
      assert_equal Date.current.in_time_zone.change(hour: 1), log.reload.ended_at
    end

    # a workout without a timer has nothing to edit, and another user's is not found
    plain = @user.workout_logs.create!(workout: "Legs", date: Date.current)
    get edit_workout_log_timer_path(plain)
    assert_redirected_to workout_logs_path
    others = @admin.workout_logs.create!(workout: "Push", date: Date.current, started_at: 1.hour.ago)
    patch workout_log_timer_path(others), params: { finished_at: "01:00" }
    assert_response :not_found
  end

  test "while the timer is paused, the workout's pages carry the alert for adding and leaving" do
    get workout_day_path(@day)
    assert_select "#timer-alert-modal", 0

    post workout_day_timer_path(@day, date: Date.current)
    log = @user.workout_logs.sole
    alert = "#timer-alert-modal[data-controller='timer-alert'][data-timer-alert-url-value='#{workout_log_timer_path(log)}']"
    get workout_day_path(@day)
    assert_select "#{alert}[data-timer-alert-paused-value='false'][data-timer-alert-leave-value='true']"

    post pause_workout_log_timer_path(log)
    get workout_day_path(@day)
    assert_select "#{alert}[data-timer-alert-paused-value='true'][data-timer-alert-leave-value='true']"
    assert_select "button[data-alert-when-paused='add']", text: /Add exercise/
    # opening one of the workout's exercises is not leaving it
    assert_select "[data-stays-in-workout] a[href=?]", workout_exercise_path(@bench_plan, date: Date.current)

    get workout_log_path(log)
    assert_select "#{alert}[data-timer-alert-paused-value='true'][data-timer-alert-leave-value='true']"
    assert_select "[data-stays-in-workout] form[data-alert-when-paused='add']", text: /Add/

    # the exercise page asks before a set is added, but leaving it is not leaving the workout
    get workout_exercise_path(@bench_plan, date: Date.current)
    assert_select "#{alert}[data-timer-alert-paused-value='true'][data-timer-alert-leave-value='false']"
    assert_select "form.set-form[data-alert-when-paused='add']"
  end
end
