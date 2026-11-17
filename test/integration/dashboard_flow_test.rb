require "test_helper"

# The dashboard: calendar, this week, the Today box and the recent workouts.
class DashboardFlowTest < FlowTest
  test "the dashboard has a weekly summary with the days behind a toggle, and no totals boxes" do
    sign_in @user
    split = @user.splits.create!(name: "PPL")
    push = split.workout_days.create!(day: "Push", weekday: 1)

    travel_to Time.zone.local(2026, 11, 16, 12) do
      get root_path
      assert_select ".stat-tile", 0
      assert_equal %w[0 0 0 –], css_select(".week-summary dd").map { |n| n.text.squish }
      assert_select ".week-overview-days li", 7
      assert_select ".week-overview-days li.is-today .week-overview-name", "Mon"
      assert_select ".week-overview .toggle-days[data-bs-target='#week-days'][aria-expanded=false]", 1
      assert_select "#week-days.collapse:not(.show) .week-overview-days", 1

      log = push.workout_logs.create!(date: Date.current)
      bench = log.workout_log_exercises.create!(name: "Bench press")
      bench.workout_sets.create!(reps_completed: 8, weight_used: 60)
      bench.workout_sets.create!(reps_completed: 6, weight_used: 72.5)
      log.workout_log_exercises.create!(name: "Dips").workout_sets.create!(reps_completed: 12)
      # a session of last week is not part of this week
      push.workout_logs.create!(date: Date.new(2026, 11, 9)).workout_log_exercises.create!(name: "Old").workout_sets.create!(reps_completed: 5, weight_used: 200)

      get root_path
      # workouts, exercises, sets, top weight
      assert_equal ["1", "2", "3", "72.5 kg"], css_select(".week-summary dd").map { |n| n.text.squish }
      assert_select ".week-overview-days li.has-workout", 1
      assert_select ".week-overview-days a[href=?]", workout_log_path(log, from: "dashboard"), text: "Push"
      assert_select ".today", /Logged today · 2 exercises · 3 sets · top 72.5 kg/
      assert_select ".today a.btn-primary[href=?]", workout_day_path(push), text: "Continue"
    end
  end

  test "deleting a workout opened from the dashboard goes back to the dashboard" do
    sign_in @user
    push = @user.splits.create!(name: "PPL").workout_days.create!(day: "Push", weekday: 1)
    log = push.workout_logs.create!(date: Date.new(2026, 11, 16))
    other = push.workout_logs.create!(date: Date.new(2026, 11, 9))

    get workout_log_path(log, from: "dashboard")
    assert_select "form[action=?] input[name=_method][value=delete]", workout_log_path(log, from: "dashboard")
    delete workout_log_path(log, from: "dashboard")
    assert_redirected_to root_path
    assert_not WorkoutLog.exists?(log.id)

    # from anywhere else it still goes to History
    delete workout_log_path(other)
    assert_redirected_to workout_logs_path
  end

  test "a recent workout is a dropdown: heaviest set per exercise as pills that open the rest of the sets" do
    sign_in @user
    split = @user.splits.create!(name: "PPL")
    push = split.workout_days.create!(day: "Push", weekday: 1)
    log = push.workout_logs.create!(date: Date.new(2026, 11, 16), notes: "Felt strong")
    bench = log.workout_log_exercises.create!(name: "Bench press")
    bench.workout_sets.create!(reps_completed: 10, weight_used: 60)
    bench.workout_sets.create!(reps_completed: 5, weight_used: 80)
    log.workout_log_exercises.create!(name: "Cable fly")

    travel_to Time.zone.local(2026, 11, 16, 12) do
      get root_path
      row = ".recent-row"
      # collapsed summary: name, date and sets, split
      assert_select "#{row} .recent-toggle[aria-expanded=false][data-bs-target='#recent-log-#{log.id}']", 1
      assert_select "#{row} .recent-toggle", /Push\s+November 16, 2026 · 2 sets/
      assert_select "#{row} .recent-toggle .chip", "PPL"
      assert_select "#recent-log-#{log.id}.collapse:not(.show)", 1
      # the whole row is not a link any more: the only link out is "Open workout"
      assert_select "#{row} a.stretched-link", 0
      assert_select "#recent-log-#{log.id} a[href=?]", workout_log_path(log, from: "dashboard"), text: /Open workout/
      assert_select "#recent-log-#{log.id} .recent-counts", "1 exercise · 2 sets"
      assert_select "#recent-log-#{log.id} .recent-notes", "Felt strong"
      # an exercise is a pill with its heaviest set; it opens every set in order
      assert_select ".lift-pill[data-bs-target='#recent-lift-#{bench.id}'] .top-set", "80 kg × 5 reps"
      assert_equal ["Set 1 60 kg × 10 reps", "Set 2 80 kg × 5 reps"],
                   css_select("#recent-lift-#{bench.id} li").map { |n| n.text.squish }
      # an exercise without sets has nothing to open
      assert_select ".lift-pill.is-empty", /Cable fly\s+No sets/
    end
  end

  test "the dashboard shows the month, this week, today's workout and last time's heaviest sets" do
    sign_in @user
    split = @user.splits.create!(name: "PPL")
    push = split.workout_days.create!(day: "Push", weekday: 1)
    split.workout_days.create!(day: "Pull", weekday: 3)

    # Monday 16 November 2026
    travel_to Time.zone.local(2026, 11, 16, 12) do
      get root_path
      assert_select "a[href=?]", new_split_path, count: 0

      # the month, Sunday first, with this week's row and today marked
      assert_select ".calendar-card h2", "November 2026"
      assert_select ".calendar-week:not(.calendar-head)", 5
      assert_select ".calendar-week.is-current-week", 1
      assert_equal %w[15 16 17 18 19 20 21], css_select(".is-current-week .calendar-day").map(&:text)
      assert_select ".calendar-day.is-today", text: "16", count: 1
      assert_select ".calendar-day.is-outside", 5
      # nothing is logged yet, so no day is highlighted, whatever the split plans
      assert_select ".calendar-day.has-workout", 0
      assert_select ".calendar a", 0

      # the active split's week, with today ringed
      assert_select ".week .week-day.is-today", 1
      assert_select ".week .week-day.is-today.is-set .week-label", "Push"

      # today's workout, nothing logged before
      assert_select ".today .eyebrow", /Today · Monday, November 16/
      assert_select ".today-title", "Push day"
      # nothing is logged yet, so the button starts the workout by opening its day
      assert_select ".today a.btn-primary[href=?]", workout_day_path(push), text: "Start workout"
      assert_equal 0, WorkoutLog.count
      assert_select ".today", /not logged a Push session before today/
      assert_select ".last-lifts", 0

      # last week's session: the heaviest set of each exercise, most reps between equal weights
      last = push.workout_logs.create!(date: Date.new(2026, 11, 9))
      bench = last.workout_log_exercises.create!(exercise: @bench, name: "Bench press")
      bench.workout_sets.create!(reps_completed: 10, weight_used: 60)
      bench.workout_sets.create!(reps_completed: 5, weight_used: 80)
      bench.workout_sets.create!(reps_completed: 6, weight_used: 80)
      dips = last.workout_log_exercises.create!(name: "Dips")
      dips.workout_sets.create!(reps_completed: 12)
      dips.workout_sets.create!(reps_completed: 15)
      older = push.workout_logs.create!(date: Date.new(2026, 11, 2))
      older.workout_log_exercises.create!(name: "Old lift").workout_sets.create!(reps_completed: 1, weight_used: 200)
      # today's own sets are not "last time"
      push.workout_logs.create!(date: Date.current).workout_log_exercises.create!(name: "Today lift")

      get root_path
      assert_select ".today-last a[href=?]", workout_log_path(last, from: "dashboard"), text: "Monday, November 9"
      assert_equal ["Bench press", "Dips"], css_select(".last-lifts .row-title").map(&:text)
      assert_equal ["80 kg × 6 reps", "Bodyweight × 15 reps"], css_select(".last-lifts .top-set").map { |n| n.text.squish }

      # the calendar highlights exactly the days a workout was logged on (the 2nd, the 9th and today),
      # and each is a link to what was recorded that day
      assert_equal %w[2 9 16], css_select(".calendar-day.has-workout").map(&:text)
      assert_select "a.calendar-day.has-workout[href=?]", workout_log_path(last, from: "dashboard"), text: "9"
      assert_select "a.calendar-day.has-workout[href=?]", workout_log_path(older, from: "dashboard"), text: "2"
      assert_select "a.calendar-day.has-workout.is-today[aria-current=date]", text: "16"
      assert_select "a.calendar-day[aria-label=?]", "Monday, November 9: Push workout"
      # a planned day with nothing logged (Wednesday the 18th is a Pull day) is plain text
      assert_select "span.calendar-day:not(.has-workout)", text: "18"
      # opening one shows the workout and its exercises, and goes back to the dashboard
      get workout_log_path(last, from: "dashboard")
      assert_select "h1", "Push workout"
      assert_equal ["Bench press", "Dips"], css_select(".entry-card h2").map(&:text)
      assert_select ".back-link[href=?]", root_path, text: "Dashboard"

      # a day with two workouts (the second from another split) opens that day's list, which leads to each of them
      pull_day = @user.splits.create!(name: "Other").workout_days.create!(day: "Pull", weekday: 1)
      pull_log = pull_day.workout_logs.create!(date: Date.new(2026, 11, 9))
      someone_else = @admin.splits.create!(name: "Theirs").workout_days.create!(day: "Legs", weekday: 1)
      someone_else.workout_logs.create!(date: Date.new(2026, 11, 10))
      get root_path
      assert_equal %w[2 9 16], css_select(".calendar-day.has-workout").map(&:text)
      assert_select "a.calendar-day[href=?]", workout_logs_path(date: "2026-11-09", from: "dashboard"), text: "9"
      assert_select "a.calendar-day[aria-label=?]", "Monday, November 9: Push and Pull workouts"
      get workout_logs_path(date: "2026-11-09", from: "dashboard")
      assert_select "h1", "Workouts on November 09, 2026"
      assert_select ".back-link[href=?]", root_path, text: "Dashboard"
      assert_select "table.app-table tbody tr", 2
      assert_select "a[href=?]", workout_log_path(pull_log, from: "dashboard")
      assert_select "a[href=?]", workout_log_path(last, from: "dashboard")
      # reached without the dashboard it goes back to the history; a day with nothing, or a bad date, is handled
      get workout_logs_path(date: "2026-11-09")
      assert_select ".back-link[href=?]", workout_logs_path, text: "History"
      get workout_logs_path(date: "2026-11-10")
      assert_select ".empty-state", /No workouts were logged on this day/
      get workout_logs_path(date: "not-a-date")
      assert_redirected_to workout_logs_path
      pull_log.destroy!
      get root_path

      # the ring is around the split only; today's exercises are in their own box below it
      assert_select ".split-card.is-active .week", 1
      assert_select ".split-card.is-active .today, .split-card.is-active .last-lifts", 0
      assert_select ".split-card.is-active + .card.today .last-lifts", 1

      # opened from the dashboard, last time's workout goes back to the dashboard
      get workout_log_path(last, from: "dashboard")
      assert_select ".back-link[href=?]", root_path, text: "Dashboard"
      get workout_log_path(last)
      assert_select ".back-link[href=?]", workout_day_path(push), text: "Push"
    end

    # after changing split, last time is still found: Lower is the same workout as Legs,
    # and the latest session counts whichever split it was done in
    travel_to Time.zone.local(2026, 11, 20, 12) do
      legs = split.workout_days.create!(day: "Legs", weekday: 4)
      legs_log = legs.workout_logs.create!(date: Date.new(2026, 11, 19))
      legs_log.workout_log_exercises.create!(exercise: @squat, name: "Squat").workout_sets.create!(reps_completed: 5, weight_used: 100)
      upper_lower = @user.splits.create!(name: "Upper lower")
      upper_lower.workout_days.create!(day: "Lower", weekday: 5)
      someone_else = @admin.splits.create!(name: "Theirs").workout_days.create!(day: "Lower", weekday: 4)
      someone_else.workout_logs.create!(date: Date.new(2026, 11, 19)).workout_log_exercises.create!(name: "Not mine")
      patch activate_split_path(upper_lower)

      get root_path
      assert_select ".today-title", "Lower day"
      assert_select ".today-last a[href=?]", workout_log_path(legs_log, from: "dashboard"), text: "Thursday, November 19"
      assert_select ".today-last .last-source", /Legs in PPL/
      assert_equal ["Squat"], css_select(".last-lifts .row-title").map(&:text)
      assert_equal ["100 kg × 5 reps"], css_select(".last-lifts .top-set").map { |n| n.text.squish }
    end

    # Tuesday: nothing planned
    travel_to Time.zone.local(2026, 11, 17, 12) do
      logs_before = WorkoutLog.count
      get root_path
      assert_select ".today-title", "Rest day"
      assert_select ".today", /No workout is planned for Tuesday/
      # a rest day can still start any workout of the split: its pop-up opens that workout day
      User.find(@user.id).current_split.workout_days.each do |day|
        assert_select ".today-start button", text: day.day
        assert_select ".modal a[href=?]", workout_day_path(day), text: "Train as extra"
      end
      assert_equal logs_before, WorkoutLog.count, "starting a workout logs nothing until an exercise is added"
      assert_select ".week .week-day.is-today.is-set", 0
      assert_select ".week .week-day.is-today", 1
    end
  end

  test "a workout logged in a split that was deleted is still last time's workout" do
    sign_in @user
    old_split = @user.splits.create!(name: "Old split")
    push = old_split.workout_days.create!(day: "Push", weekday: 1)
    planned = push.workout_exercises.create!(exercise: @bench)

    # Monday 16 November 2026: train Push
    travel_to Time.zone.local(2026, 11, 16, 12) do
      post workout_exercise_workout_sets_path(planned), params: { workout_set: { reps_completed: 8, weight_used: 60 } }
    end
    log = @user.workout_logs.sole

    # change split and delete the old one: the record stays
    new_split = @user.splits.create!(name: "New split")
    new_split.workout_days.create!(day: "Push", weekday: 2)
    delete split_path(old_split)
    assert_equal [log], @user.workout_logs.to_a

    # Tuesday: Push again, in the new split
    travel_to Time.zone.local(2026, 11, 17, 12) do
      get root_path
      assert_select ".today-title", "Push day"
      assert_select ".today-last a[href=?]", workout_log_path(log, from: "dashboard"), text: "Monday, November 16"
      assert_select ".today-last .last-source", /from a deleted split/
      assert_equal ["Bench press"], css_select(".last-lifts .row-title").map(&:text)
      assert_equal ["60 kg × 8 reps"], css_select(".last-lifts .top-set").map { |n| n.text.squish }

      # the old workout still opens, can still be edited, and is listed in the history
      get workout_log_path(log)
      assert_select "h1", "Push workout"
      assert_select ".back-link[href=?]", workout_logs_path
      entry = log.workout_log_exercises.sole
      post workout_log_exercise_workout_sets_path(entry), params: { workout_set: { reps_completed: 6, weight_used: 65 } }
      assert_equal 2, entry.workout_sets.count
      get edit_workout_log_exercise_path(entry)
      assert_response :success
      get workout_logs_path
      assert_select "td", text: "Push"
    end
  end

  test "today follows the time zone the browser reports" do
    sign_in @user
    split = @user.splits.create!(name: "PPL")
    split.workout_days.create!(day: "Push", weekday: 1)
    planned = split.workout_days.first.workout_exercises.create!(exercise: @bench, name: "Bench press")

    # 01:00 UTC on Tuesday 1 December is still Monday 30 November in São Paulo and already Tuesday in Tokyo
    travel_to Time.utc(2026, 12, 1, 1) do
      get root_path
      assert_select "body[data-time-zone=?]", "Etc/UTC"
      assert_select ".calendar-card h2", "December 2026"
      assert_select ".today-title", "Rest day"

      cookies[:time_zone] = "America/Sao_Paulo"
      get root_path
      assert_select "body[data-time-zone=?][data-reloadable=true]", "America/Sao_Paulo"
      assert_select ".calendar-card h2", "November 2026"
      assert_select ".calendar-day.is-today", text: "30"
      assert_select ".today .eyebrow", /Monday, November 30/
      assert_select ".today-title", "Push day"

      # sets are logged under the user's own date too
      post workout_exercise_workout_sets_path(planned), params: { workout_set: { reps_completed: 8, weight_used: 60 } }
      assert_equal Date.new(2026, 11, 30), @user.workout_logs.last.date

      cookies[:time_zone] = "Asia/Tokyo"
      get root_path
      assert_select ".calendar-card h2", "December 2026"
      assert_select ".today-title", "Rest day"

      # the reported zone is remembered on the user
      assert_equal "Asia/Tokyo", @user.reload.time_zone

      # a zone the server does not know falls back to the last one it did know
      cookies[:time_zone] = "Not/AZone"
      get root_path
      assert_select "body[data-time-zone=?]", "Asia/Tokyo"
      assert_equal "Asia/Tokyo", @user.reload.time_zone

      # a browser that has not reported a zone yet (new session, no JavaScript) starts in the saved one
      cookies.delete :time_zone
      @user.update_column(:time_zone, "America/Sao_Paulo")
      get root_path
      assert_select "body[data-time-zone=?]", "America/Sao_Paulo"
      assert_select ".today-title", "Push day"
    end
  end

  test "once today's workout has sets the dashboard shows them, with last time as a link" do
    sign_in @user
    split = @user.splits.create!(name: "Upper lower")
    upper = split.workout_days.create!(day: "Upper", weekday: 1)
    planned = upper.workout_exercises.create!(exercise: @bench)

    # Monday 16 November 2026
    travel_to Time.zone.local(2026, 11, 16, 12) do
      last = upper.workout_logs.create!(date: Date.new(2026, 11, 15))
      last.workout_log_exercises.create!(name: "Old lift").workout_sets.create!(reps_completed: 6, weight_used: 80)

      get root_path
      assert_equal ["Old lift"], css_select(".last-lifts .row-title").map(&:text)
      assert_select ".today-lifts", 0

      post workout_exercise_workout_sets_path(planned), params: { workout_set: { reps_completed: 8, weight_used: 60 } }
      post workout_exercise_workout_sets_path(planned), params: { workout_set: { reps_completed: 5, weight_used: 70 } }
      today = @user.workout_logs.find_by!(date: Date.current)
      # an exercise opened today without a set yet is not listed
      today.workout_log_exercises.create!(name: "No sets yet")

      get root_path
      assert_select ".today-done a[href=?]", workout_log_path(today, from: "dashboard"), text: "2 sets"
      assert_equal ["Bench press"], css_select(".today-lifts .row-title").map(&:text)
      assert_equal ["70 kg × 5 reps"], css_select(".today-lifts .top-set").map { |n| n.text.squish }
      # last time is still one tap away, but its sets no longer stand in for today's
      assert_select ".last-lifts", 0
      assert_select ".today-previous a[href=?]", workout_log_path(last, from: "dashboard"), text: "Sunday, November 15"
    end
  end
end
