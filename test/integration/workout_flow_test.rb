require "test_helper"

class WorkoutFlowTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @admin = User.create!(email: "admin@example.com", password: "secret123", admin: true)
    @user = User.create!(email: "lifter@example.com", password: "secret123")
    @bench = Exercise.create!(name: "Bench press", muscle_group: "Chest")
    @squat = Exercise.create!(name: "Squat", muscle_group: "Legs")
  end

  test "signed-out visitors see the landing page and are sent to login elsewhere" do
    get root_path
    assert_response :success
    assert_select "h1", /Plan your training/

    get splits_path
    assert_redirected_to new_user_session_path
  end

  test "devise pages render" do
    [new_user_session_path, new_user_registration_path, new_user_password_path].each do |path|
      get path
      assert_response :success
    end
    sign_in @user
    get edit_user_registration_path
    assert_response :success
  end

  test "a split is a week, Sunday to Saturday" do
    sign_in @user
    get new_split_path
    assert_response :success
    post splits_path, params: { split: { name: "" } }
    assert_response :unprocessable_entity
    post splits_path, params: { split: { name: "PPL" } }
    # Not @user.splits.last: the signed-in user is this same object, and the rejected
    # split above is still sitting unsaved in its association.
    split = Split.order(:id).last
    assert_equal @user, split.user
    assert_redirected_to split

    # an empty week: seven blank circles, each starting a workout day on its weekday
    get split_path(split)
    assert_select ".week .week-day", 7
    assert_select ".week .week-day.is-set", 0
    assert_equal %w[S M T W T F S], css_select(".week .week-circle").map(&:text)
    assert_select ".week a[href=?]", new_split_workout_day_path(split, weekday: 1)

    get new_split_workout_day_path(split, weekday: 1)
    assert_select "select[name='workout_day[weekday]'] option[selected]", text: "Monday"
    # the workout is chosen from the list, not typed
    assert_equal ["Choose a workout", *WorkoutDay::NAMES], css_select("select[name='workout_day[day]'] option").map(&:text)
    post split_workout_days_path(split), params: { workout_day: { day: "Chest day", weekday: 1 } }
    assert_response :unprocessable_entity
    post split_workout_days_path(split), params: { workout_day: { day: "Push", weekday: 1 } }
    day = split.workout_days.last
    assert_redirected_to day
    assert_equal "Monday", day.weekday_name

    # one workout per weekday
    post split_workout_days_path(split), params: { workout_day: { day: "Pull", weekday: 1 } }
    assert_response :unprocessable_entity
    post split_workout_days_path(split), params: { workout_day: { day: "Pull" } }
    assert_response :unprocessable_entity
    assert_equal 1, split.workout_days.count

    # Monday is now coloured and opens the day; the next free weekday is offered for a new day
    get split_path(split)
    assert_select ".week .week-day.is-set", 1
    assert_select ".week a.is-set[href=?]", workout_day_path(day)
    assert_select ".week a.is-set .week-label", "Push"
    get new_split_workout_day_path(split)
    assert_select "select[name='workout_day[weekday]'] option[selected]", text: "Sunday"

    get edit_workout_day_path(day)
    assert_response :success
    patch workout_day_path(day), params: { workout_day: { weekday: 5 } }
    assert_equal "Friday", day.reload.weekday_name
    get edit_split_path(split)
    assert_response :success

    [splits_path, root_path].each do |path|
      get path
      assert_response :success, "#{path} failed"
    end

    delete workout_day_path(day)
    assert_redirected_to split
    delete split_path(split)
    assert_equal 0, @user.splits.count
  end

  test "one split is active, is ringed on the splits page and shown on the dashboard" do
    sign_in @user
    get root_path
    assert_select ".split-card .empty-state a[href=?]", new_split_path

    ppl = @user.splits.create!(name: "PPL")
    upper_lower = @user.splits.create!(name: "Upper lower")
    upper_lower.workout_days.create!(day: "Upper", weekday: 2)

    # until one is chosen, the oldest split is the active one
    get splits_path
    assert_select ".split-card", 2
    assert_select ".split-card.is-active", 1
    assert_select ".split-card.is-active h2", "PPL"
    assert_select ".split-card.is-active .split-active-badge", /Active/
    assert_select ".split-card.is-active form", 0
    assert_select ".split-card:not(.is-active) form[action=?]", activate_split_path(upper_lower)

    # changed on the splits page: the user stays there
    patch activate_split_path(upper_lower), headers: { "HTTP_REFERER" => splits_url }
    assert_redirected_to splits_url
    assert_equal upper_lower, @user.reload.active_split
    follow_redirect!
    assert_select ".split-card.is-active h2", "Upper lower"
    assert_select ".back-link", 0
    assert_select ".split-card:not(.is-active) form[action=?]", activate_split_path(ppl)

    # the split page says whether it is active, and offers the change if not
    get split_path(upper_lower)
    assert_select ".header-actions .split-active-badge", /Active split/
    get split_path(ppl)
    assert_select ".header-actions form[action=?]", activate_split_path(ppl)

    # the dashboard shows the active split and its week
    get root_path
    assert_select ".split-card.is-active h2", "Upper lower"
    assert_select ".split-card.is-active .week a.is-set .week-label", "Upper"
    assert_select ".split-card.is-active a[href=?]", splits_path(from: "dashboard"), text: "Change"

    # changed from the dashboard: "Change" opens the splits, and choosing one returns to the dashboard
    get splits_path(from: "dashboard")
    assert_select ".back-link[href=?]", root_path
    assert_select ".split-card:not(.is-active) form[action=?]", activate_split_path(ppl, from: "dashboard")
    patch activate_split_path(ppl, from: "dashboard"), headers: { "HTTP_REFERER" => splits_url(from: "dashboard") }
    assert_redirected_to root_path
    follow_redirect!
    assert_select ".split-card.is-active h2", "PPL"
    patch activate_split_path(upper_lower)

    # someone else's split cannot be activated
    others = @admin.splits.create!(name: "Not mine")
    patch activate_split_path(others)
    assert_response :not_found
    assert_equal upper_lower, @user.reload.active_split
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
      assert_select ".today a[href=?]", workout_day_path(push), text: "Open workout"
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
      get root_path
      assert_select ".today-title", "Rest day"
      assert_select ".today", /No workout is planned for Tuesday/
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

  test "adding exercises to a day from the catalogue or by creating one" do
    sign_in @user
    day = @user.splits.create!(name: "PPL").workout_days.create!(day: "Push", weekday: 1)
    other_users_exercise = Exercise.create!(name: "Secret lift", muscle_group: "Chest", user: @admin)

    # an empty day offers "Add exercise", which opens the catalogue grouped by muscle group
    get workout_day_path(day)
    assert_select ".empty-state button[data-bs-target='#exercise-picker']", text: /Add exercise/
    assert_equal %w[Chest Legs], css_select("#exercise-picker-form .picker-group").map(&:text)
    assert_select "#exercise-picker label", text: /Bench press/
    assert_select "#exercise-picker label", text: /Secret lift/, count: 0
    assert_select "#exercise-picker input[name='exercise[name]']"

    post workout_day_workout_exercises_path(day), params: { exercise_ids: [] }
    assert_match "Choose at least one exercise", flash[:alert]
    post workout_day_workout_exercises_path(day), params: { exercise_ids: [other_users_exercise.id] }
    assert_match "Choose at least one exercise", flash[:alert]
    assert_equal 0, day.workout_exercises.count

    post workout_day_workout_exercises_path(day), params: { exercise_ids: [@bench.id, @squat.id] }
    assert_redirected_to day
    assert_equal ["Bench press", "Squat"], day.workout_exercises.order(:id).pluck(:name)
    assert_equal ["free_weights"], day.workout_exercises.pluck(:equipment).uniq

    # an exercise is on a day once: ticked again, or typed again under any spelling, nothing is added
    post workout_day_workout_exercises_path(day), params: { exercise_ids: [@bench.id] }
    assert_match "already on this day", flash[:alert]
    assert_no_difference "Exercise.count" do
      post workout_day_workout_exercises_path(day), params: { exercise: { name: " bench  PRESS ", muscle_group: "Chest" } }
    end
    assert_match "already on this day", flash[:alert]
    assert_equal 2, day.workout_exercises.count

    # creating an exercise makes it the user's own and adds it to the day
    post workout_day_workout_exercises_path(day), params: { exercise: { name: "", muscle_group: "Chest" } }
    assert_match "Name can't be blank", flash[:alert]
    # a regular user cannot put it in the shared catalogue, whatever the form sends
    post workout_day_workout_exercises_path(day), params: { exercise: { name: "Pec deck", muscle_group: "Chest", shared: "1" } }
    assert_equal @user, Exercise.find_by!(name: "Pec deck").user
    delete workout_exercise_path(day.workout_exercises.order(:id).last)
    Exercise.find_by!(name: "Pec deck").destroy!
    get workout_day_path(day)
    assert_select "#exercise-picker input[name='exercise[shared]']", 0
    assert_difference "@user.exercises.count", 1 do
      post workout_day_workout_exercises_path(day), params: { exercise: { name: "Cable fly", muscle_group: "Chest" } }
    end
    own = @user.exercises.last
    assert_equal ["Cable fly", "Chest"], [own.name, own.muscle_group]
    assert_equal own, day.workout_exercises.order(:id).last.exercise
    assert_equal 0, Exercise.shared.where(name: "Cable fly").count
    # a single added exercise opens straight away, ready for its first set
    assert_redirected_to workout_exercise_path(day.workout_exercises.order(:id).last)

    # the day lists its exercises; the modal marks them as added and shows the user's own exercise
    get workout_day_path(day)
    assert_select ".list-rows .row-title", text: "Cable fly"
    assert_select ".empty-state", text: /No exercises for this day/, count: 0
    assert_select "#exercise-picker label.is-taken", 3
    assert_select "#exercise-picker label", text: /Cable fly.*Yours/m
    # the day is only the program: each exercise can be removed on the spot, and no logged workouts are listed
    assert_select ".list-rows li form[action='#{workout_exercise_path(day.workout_exercises.first)}'] button[aria-label='Remove Bench press']"
    assert_select "h2", text: "Logged workouts", count: 0

    # other users do not see it, the owner can delete it once it is out of every plan
    get exercises_path
    assert_select "td", text: /Cable fly/
    delete exercise_path(own)
    assert_match "was not deleted", flash[:alert]
    delete workout_exercise_path(day.workout_exercises.find_by!(exercise: own))
    assert_redirected_to day
    delete exercise_path(own)
    assert_not Exercise.exists?(own.id)

    # an exercise an admin creates in the modal is the admin's own, unless they share it
    sign_out @user
    sign_in @admin
    admin_day = @admin.splits.create!(name: "Admin").workout_days.create!(day: "Legs", weekday: 2)
    get workout_day_path(admin_day)
    assert_select "#exercise-picker input[type=checkbox][name='exercise[shared]']:not([checked])", 1
    post workout_day_workout_exercises_path(admin_day), params: { exercise: { name: "Leg curl", muscle_group: "Legs", shared: "0" } }
    assert_equal @admin, Exercise.find_by!(name: "Leg curl").user
    post workout_day_workout_exercises_path(admin_day), params: { exercise: { name: "Leg extension", muscle_group: "Legs", shared: "1" } }
    assert Exercise.shared.exists?(name: "Leg extension")
    assert_equal ["Leg curl", "Leg extension"], admin_day.workout_exercises.order(:id).pluck(:name)
  end

  test "opening an exercise and adding sets" do
    sign_in @user
    day = @user.splits.create!(name: "PPL").workout_days.create!(day: "Push", weekday: 1)
    planned = day.workout_exercises.create!(exercise: @bench)

    get workout_exercise_path(planned)
    assert_response :success
    assert_select "h1", "Bench press"
    assert_select "button", text: /Add set/
    assert_select "input[name='workout_set[set_number]']", 0
    assert_equal 0, @user.workout_logs.count

    # an invalid set leaves no empty workout behind
    post workout_exercise_workout_sets_path(planned), params: { workout_set: { reps_completed: "", weight_used: 80 } }
    assert_redirected_to workout_exercise_path(planned)
    assert_match "Reps completed can't be blank", flash[:alert]
    assert_equal 0, @user.workout_logs.count

    # sets are numbered automatically and go into today's workout
    post workout_exercise_workout_sets_path(planned), params: { workout_set: { reps_completed: 8, weight_used: 80 } }
    assert_redirected_to workout_exercise_path(planned)
    post workout_exercise_workout_sets_path(planned), params: { workout_set: { reps_completed: 6, weight_used: 82.5 } }
    log = @user.workout_logs.sole
    assert_equal Date.current, log.date
    entry = log.workout_log_exercises.sole
    assert_equal ["Bench press", planned], [entry.name, entry.workout_exercise]
    assert_equal [[1, 8, 80], [2, 6, 82.5]], entry.workout_sets.order(:set_number).pluck(:set_number, :reps_completed, :weight_used)

    # the form is pre-filled with the last set
    get workout_exercise_path(planned)
    assert_select "table.set-table tbody[data-controller='row-edit']", 2
    assert_select "input[name='workout_set[reps_completed]'][value='6']"
    assert_select "input[name='workout_set[weight_used]'][value='82.5']"

    # weight comes before reps, in the table and in the form
    assert_equal %w[Set Weight Reps], css_select("table.set-table th").map(&:text).reject(&:empty?)
    assert_operator response.body.index("workout_set[weight_used]"), :<, response.body.index("workout_set[reps_completed]")

    # a recorded set can be corrected in place
    second = entry.workout_sets.find_by!(set_number: 2)
    # the forms say which exercise page they are on, so saving returns there without relying on the referer
    on_exercise_page = workout_set_path(second, workout_exercise_id: planned.id)
    assert_select "form#edit_set_#{second.id}[action='#{on_exercise_page}']"
    # weight, reps and a note
    assert_select "input[form='edit_set_#{second.id}']", 3
    assert_select "input[form='edit_set_#{second.id}'][name='workout_set[notes]']", 1
    patch on_exercise_page, params: { workout_set: { reps_completed: 5, weight_used: 85.125, notes: "  Paused   reps " } }
    assert_redirected_to workout_exercise_path(planned)
    assert_equal [2, 5, BigDecimal("85.125"), "Paused reps"],
                 second.reload.then { |s| [s.set_number, s.reps_completed, s.weight_used, s.notes] }
    follow_redirect!
    assert_select "tr.set-note td", text: /Paused reps/
    # three decimals are shown and pre-filled as typed
    assert_select "td span", text: "85.125 kg"
    assert_select "input[name='workout_set[weight_used]'][value='85.125']"
    patch on_exercise_page, params: { workout_set: { reps_completed: "", weight_used: 85 } }
    assert_match "Set not updated: Reps completed can't be blank", flash[:alert]
    assert_equal 5, second.reload.reps_completed
    # without it (the logged workout page), the set's workout is where the user goes back to
    patch workout_set_path(second), params: { workout_set: { reps_completed: 5, weight_used: 85, notes: "" } }
    assert_redirected_to workout_log_path(log, anchor: "entry-#{entry.id}")
    assert_nil second.reload.notes
    # someone else's exercise page is not a way back
    theirs = @admin.splits.create!(name: "Theirs").workout_days.create!(day: "Push", weekday: 1).workout_exercises.create!(exercise: @bench)
    patch workout_set_path(second, workout_exercise_id: theirs.id), params: { workout_set: { reps_completed: 5 } }
    assert_redirected_to workout_log_path(log, anchor: "entry-#{entry.id}")

    delete on_exercise_page
    assert_redirected_to workout_exercise_path(planned)
    assert_equal 1, entry.workout_sets.count
    post workout_exercise_workout_sets_path(planned), params: { workout_set: { reps_completed: 7 } }
    assert_equal [1, 2], entry.workout_sets.order(:set_number).pluck(:set_number)

    # equipment: free weights, or a machine with a typed brand
    patch workout_exercise_path(planned), params: { workout_exercise: { equipment: "machine", machine_brand: "" } }
    assert_match "Machine brand can't be blank", flash[:alert]
    patch workout_exercise_path(planned), params: { workout_exercise: { equipment: "machine", machine_brand: "Acme" } }
    assert_redirected_to workout_exercise_path(planned)
    assert_equal "Machine · Acme", planned.reload.equipment_label
    # the sets already recorded today were done on it, so today's entry follows
    assert_equal "Machine · Acme", entry.reload.equipment_label
    patch workout_exercise_path(planned), params: { workout_exercise: { equipment: "free_weights" } }
    assert_nil planned.reload.machine_brand
    assert_equal "Free weights", entry.reload.equipment_label

    get workout_day_path(day)
    assert_select ".chip", text: "2 sets"
    # removing an exercise that has sets asks first
    assert_select "form[action='#{workout_exercise_path(planned)}'][data-turbo-confirm]"

    # removing the exercise from the day keeps what was logged
    delete workout_exercise_path(planned)
    assert_nil entry.reload.workout_exercise
    assert_equal 2, entry.workout_sets.count
  end

  test "a logged workout can be reviewed and corrected" do
    sign_in @user
    day = @user.splits.create!(name: "PPL").workout_days.create!(day: "Push", weekday: 1)
    planned = day.workout_exercises.create!(exercise: @bench)
    unused = day.workout_exercises.create!(exercise: @squat)
    post workout_exercise_workout_sets_path(planned), params: { workout_set: { reps_completed: 8, weight_used: 80 } }
    log = @user.workout_logs.sole
    entry = log.workout_log_exercises.sole

    [workout_log_path(log), workout_logs_path, workout_day_path(day), root_path].each do |path|
      get path
      assert_response :success, "#{path} failed"
    end

    get workout_log_path(log)
    assert_select "h2", "Bench press"
    assert_select "h2", "From this day, not in this workout"

    post workout_log_exercise_workout_sets_path(entry), params: { workout_set: { reps_completed: 8 } }
    assert_equal [1, 2], entry.workout_sets.order(:set_number).pluck(:set_number)
    post workout_log_exercise_workout_sets_path(entry), params: { workout_set: { set_number: 1, reps_completed: 8 } }
    assert_match "Set number has already been taken", flash[:alert]

    patch workout_log_path(log), params: { workout_log: { notes: "Felt strong" } }
    assert_equal "Felt strong", log.reload.notes

    # adding exercises: one from the day, some from the catalogue, one created on the spot
    post workout_log_workout_log_exercises_path(log), params: { workout_exercise_id: unused.id }
    # an exercise is in a workout once: Bench press is already there, and so is Squat now
    post workout_log_workout_log_exercises_path(log), params: { exercise_ids: [@bench.id] }
    assert_match "Nothing added: Bench press is already in this workout", flash[:alert]
    post workout_log_workout_log_exercises_path(log), params: { exercise_ids: [@squat.id] }
    assert_match "Squat is already in this workout", flash[:alert]
    post workout_log_workout_log_exercises_path(log), params: { exercise: { name: "Dips", muscle_group: "Triceps" } }
    post workout_log_workout_log_exercises_path(log), params: { exercise_ids: [] }
    assert_match "Choose at least one exercise", flash[:alert]
    assert_equal ["Bench press", "Squat", "Dips"], log.workout_log_exercises.order(:id).pluck(:name)
    assert_equal "Dips", @user.exercises.sole.name
    # every exercise of the day is in the workout, so none is offered again
    get workout_log_path(log)
    assert_select "h2", text: "From this day, not in this workout", count: 0

    # the equipment of a logged exercise can be changed without touching the day, and a note added
    get edit_workout_log_exercise_path(entry)
    assert_response :success
    assert_select "textarea[name='workout_log_exercise[notes]']"
    patch workout_log_exercise_path(entry), params: { workout_log_exercise: { equipment: "machine", machine_brand: "" } }
    assert_response :unprocessable_entity
    patch workout_log_exercise_path(entry), params: { workout_log_exercise: { equipment: "machine", machine_brand: "Beta", notes: "Left shoulder tight" } }
    assert_equal ["Machine · Beta", "Left shoulder tight"], entry.reload.then { |e| [e.equipment_label, e.notes] }
    assert_equal "free_weights", planned.reload.equipment

    get workout_log_path(log)
    assert_response :success
    assert_select "p", /Machine · Beta/
    assert_select "p.entry-note", /Left shoulder tight/

    delete workout_log_exercise_path(entry)
    assert_equal 2, log.workout_log_exercises.count
    delete workout_log_path(log)
    assert_redirected_to workout_logs_path
    assert_equal 0, @user.workout_logs.count
  end

  test "users cannot reach another user's records" do
    split = @admin.splits.create!(name: "Private")
    day = split.workout_days.create!(day: "Legs", weekday: 2)
    planned = day.workout_exercises.create!(exercise: @bench)
    log = day.workout_logs.create!(date: Date.current)
    entry = log.workout_log_exercises.create!(workout_exercise: planned)
    admins_own = Exercise.create!(name: "Secret lift", user: @admin)

    [split_path(split), workout_day_path(day), workout_exercise_path(planned), workout_log_path(log),
     edit_workout_log_exercise_path(entry), edit_exercise_path(admins_own), edit_exercise_path(@bench)].each do |path|
      sign_in @user # a 404 does not persist the test session, so sign in before each request
      get path
      assert_response :not_found, "#{path} was reachable"
    end

    requests = [
      -> { post workout_log_exercise_workout_sets_path(entry), params: { workout_set: { reps_completed: 8 } } },
      -> { post workout_exercise_workout_sets_path(planned), params: { workout_set: { reps_completed: 8 } } },
      -> { post workout_day_workout_exercises_path(day), params: { exercise_ids: [@bench.id] } },
      -> { post workout_log_workout_log_exercises_path(log), params: { exercise_ids: [@bench.id] } },
      -> { patch workout_exercise_path(planned), params: { workout_exercise: { equipment: "machine", machine_brand: "X" } } },
      -> { patch workout_log_exercise_path(entry), params: { workout_log_exercise: { equipment: "machine", machine_brand: "X" } } },
      -> { delete exercise_path(admins_own) }
    ]
    requests.each_with_index do |request, index|
      sign_in @user
      request.call
      assert_response :not_found, "request #{index} was allowed"
    end

    assert_equal 0, entry.workout_sets.count
    assert_equal 1, day.workout_exercises.count
    assert_equal 1, log.workout_log_exercises.count
    assert_equal "free_weights", planned.reload.equipment
    assert Exercise.exists?(admins_own.id)
  end

  test "only admins manage the exercise catalogue" do
    sign_in @user
    get exercises_path
    assert_response :success
    get new_exercise_path
    assert_redirected_to exercises_path
    post exercises_path, params: { exercise: { name: "Deadlift" } }
    assert_nil Exercise.find_by(name: "Deadlift")
    delete exercise_path(@bench)
    assert_response :not_found
    assert Exercise.exists?(@bench.id)

    sign_in @admin
    get new_exercise_path
    assert_response :success
    post exercises_path, params: { exercise: { name: "", shared: "1" } }
    assert_response :unprocessable_entity
    # the form offers the shared catalogue, ticked; unticked the exercise is the admin's own
    assert_select "input[type=checkbox][name='exercise[shared]'][checked]", 1
    post exercises_path, params: { exercise: { name: "Deadlift", muscle_group: "Back", shared: "1" } }
    deadlift = Exercise.find_by!(name: "Deadlift")
    assert deadlift.shared?
    assert_match "added to the catalogue", flash[:notice]
    post exercises_path, params: { exercise: { name: "Deadlift", muscle_group: "Back", shared: "1" } }
    assert_response :unprocessable_entity
    post exercises_path, params: { exercise: { name: "Jefferson curl", muscle_group: "Back", shared: "0" } }
    private_lift = Exercise.find_by!(name: "Jefferson curl")
    assert_equal @admin, private_lift.user
    assert_match "added to your own exercises", flash[:notice]
    # the admin manages both; another user does not see the private one
    get exercises_path
    assert_select "td", text: /Jefferson curl.*Yours/m
    assert_select "a[href=?]", edit_exercise_path(private_lift)
    assert_select "a[href=?]", edit_exercise_path(deadlift)
    patch exercise_path(private_lift), params: { exercise: { muscle_group: "Core" } }
    assert_equal "Core", private_lift.reload.muscle_group
    sign_in @user
    get exercises_path
    assert_select "td", text: /Jefferson curl/, count: 0
    assert_select "td", text: /Deadlift/
    sign_in @admin
    get edit_exercise_path(deadlift)
    assert_response :success
    patch exercise_path(deadlift), params: { exercise: { muscle_group: "Legs" } }
    assert_equal "Legs", deadlift.reload.muscle_group

    # an exercise that is in a plan is kept, with an explanation
    day = @admin.splits.create!(name: "PPL").workout_days.create!(day: "Legs", weekday: 2)
    day.workout_exercises.create!(exercise: deadlift)
    delete exercise_path(deadlift)
    assert Exercise.exists?(deadlift.id)
    assert_match "was not deleted", flash[:alert]

    delete exercise_path(@bench)
    assert_not Exercise.exists?(@bench.id)
  end

  test "every sub-page has one back button to its parent, top-level pages have none" do
    sign_in @user
    mine = Exercise.create!(name: "Cable fly", muscle_group: "Chest", user: @user)
    split = @user.splits.create!(name: "PPL")
    day = split.workout_days.create!(day: "Push", weekday: 1)
    planned = day.workout_exercises.create!(exercise: @bench)
    post workout_exercise_workout_sets_path(planned), params: { workout_set: { reps_completed: 8, weight_used: 80 } }
    log = @user.workout_logs.sole
    entry = log.workout_log_exercises.sole

    {
      edit_exercise_path(mine) => ["Exercises", exercises_path],
      new_split_path => ["Splits", splits_path],
      split_path(split) => ["Splits", splits_path],
      edit_split_path(split) => ["PPL", split_path(split)],
      new_split_workout_day_path(split) => ["PPL", split_path(split)],
      workout_day_path(day) => ["PPL", split_path(split)],
      edit_workout_day_path(day) => ["Push", workout_day_path(day)],
      workout_exercise_path(planned) => ["Push", workout_day_path(day)],
      workout_log_path(log) => ["Push", workout_day_path(day)],
      edit_workout_log_exercise_path(entry) => ["Push workout", workout_log_path(log)]
    }.each do |path, (label, parent)|
      get path
      assert_response :success, "#{path} failed"
      assert_select "a.back-link", { count: 1, text: label }, "#{path} back button"
      assert_select "a.back-link[href=?]", parent, { count: 1 }, "#{path} back target"
    end

    [root_path, splits_path, workout_logs_path, exercises_path].each do |path|
      get path
      assert_select "a.back-link", false, "#{path} should have no back button"
    end

    # a rejected form keeps pointing at the saved name, not the one being typed
    patch split_path(split), params: { split: { name: "" } }
    assert_response :unprocessable_entity
    assert_select "a.back-link", text: "PPL"

    # only an admin reaches the catalogue form
    sign_in @admin
    get new_exercise_path
    assert_select "a.back-link[href=?]", exercises_path, text: "Exercises", count: 1
  end

  test "the same workout from two splits on one day is one logged workout" do
    sign_in @user
    ppl = @user.splits.create!(name: "PPL").workout_days.create!(day: "Legs", weekday: 1)
    upper_lower = @user.splits.create!(name: "Upper lower").workout_days.create!(day: "Lower", weekday: 1)
    squat_a = ppl.workout_exercises.create!(exercise: @squat)
    squat_b = upper_lower.workout_exercises.create!(exercise: @squat)
    bench_b = upper_lower.workout_exercises.create!(exercise: @bench)

    post workout_exercise_workout_sets_path(squat_a), params: { workout_set: { reps_completed: 5, weight_used: 100 } }
    # Lower is the same workout as Legs: the other split's sets join the same session and the same entry
    post workout_exercise_workout_sets_path(squat_b), params: { workout_set: { reps_completed: 4, weight_used: 105 } }
    post workout_exercise_workout_sets_path(bench_b), params: { workout_set: { reps_completed: 8, weight_used: 60 } }

    log = @user.workout_logs.sole
    assert_equal %w[Squat Bench\ press], log.workout_log_exercises.order(:id).pluck(:name)
    assert_equal [1, 2], log.workout_log_exercises.order(:id).first.workout_sets.order(:set_number).pluck(:set_number)

    # both exercise pages and both day pages show the day's sets
    [squat_a, squat_b].each do |planned|
      get workout_exercise_path(planned)
      assert_select "table.set-table tbody[data-controller='row-edit']", 2
    end
    get workout_day_path(ppl)
    assert_select ".chip", text: "2 sets"
    get workout_day_path(upper_lower)
    assert_equal ["2 sets", "1 set"], css_select(".chip-done").map(&:text)

    # a workout cannot be moved onto a date that already has that workout
    earlier = ppl.workout_logs.create!(date: Date.current - 7)
    patch workout_log_path(earlier), params: { workout_log: { date: Date.current } }
    assert_match "Date already has a Legs workout logged", flash[:alert]
    assert_equal Date.current - 7, earlier.reload.date
  end

  test "long lists are split into pages" do
    sign_in @user
    day = @user.splits.create!(name: "PPL").workout_days.create!(day: "Push", weekday: 1)
    25.times { |i| day.workout_logs.create!(date: Date.new(2026, 1, 1) + i) }

    get workout_logs_path
    assert_select "table.app-table tbody tr", 20
    assert_select "td a", text: "January 25, 2026"
    assert_select ".pagination-bar", text: /Page 1 of 2/
    assert_select ".pagination-bar a[rel=next][href=?]", workout_logs_path(page: 2)
    assert_select ".pagination-bar a[rel=prev]", 0

    get workout_logs_path(page: 2)
    assert_select "table.app-table tbody tr", 5
    assert_select "td a", text: "January 01, 2026"
    assert_select ".pagination-bar a[rel=prev][href=?]", workout_logs_path(page: 1)
    # a page that does not exist shows the nearest one
    get workout_logs_path(page: 99)
    assert_select ".pagination-bar", text: /Page 2 of 2/
    get workout_logs_path(page: "x")
    assert_select ".pagination-bar", text: /Page 1 of 2/

    # the catalogue too; a short list has no page links
    get exercises_path
    assert_select ".pagination-bar", 0
    35.times { |i| Exercise.create!(name: "Lift #{i}", muscle_group: "Chest") }
    get exercises_path
    assert_select "table.app-table tbody tr", 30
    assert_select ".pagination-bar", text: /Page 1 of 2/
  end

  test "an admin manages the users" do
    # only an admin reaches the page or its actions
    sign_in @user
    get root_path
    assert_select "a[href=?]", admin_users_path, count: 0
    get admin_users_path
    assert_redirected_to root_path
    assert_match "Only an admin can do that", flash[:alert]
    patch admin_user_path(@user), params: { admin: "true" }
    assert_not @user.reload.admin?
    delete admin_user_path(@admin)
    assert User.exists?(@admin.id)

    sign_in @admin
    get root_path
    assert_select ".dropdown-menu a[href=?]", admin_users_path, text: "Users"
    get admin_users_path
    assert_response :success
    assert_select "a.back-link", false
    assert_select "td", text: /lifter@example.com/
    assert_select "td", text: /admin@example.com.*Admin.*You/m
    # the admin's own row has no actions
    assert_select "form[action=?]", admin_user_path(@admin), count: 0
    assert_select "form[action=?]", admin_user_path(@user), count: 2

    patch admin_user_path(@user), params: { admin: "true" }
    assert_redirected_to admin_users_path
    assert @user.reload.admin?
    patch admin_user_path(@user), params: { admin: "false" }
    assert_not @user.reload.admin?

    # an admin cannot demote or delete themselves, so one admin always remains
    patch admin_user_path(@admin), params: { admin: "false" }
    assert_match "cannot change your own account", flash[:alert]
    assert @admin.reload.admin?
    delete admin_user_path(@admin)
    assert User.exists?(@admin.id)

    # deleting a user removes everything they recorded, and nothing of the shared catalogue
    day = @user.splits.create!(name: "PPL").workout_days.create!(day: "Push", weekday: 1)
    @user.update!(active_split: day.split)
    own = Exercise.create!(name: "Cable fly", user: @user)
    [@bench, own].each do |exercise|
      day.workout_exercises.create!(exercise: exercise).entry_on!(Date.current).workout_sets.create!(reps_completed: 8)
    end
    delete admin_user_path(@user)
    assert_redirected_to admin_users_path
    assert_not User.exists?(@user.id)
    assert_equal [0, 0, 0, 0], [Split.count, WorkoutLog.count, WorkoutSet.count, Exercise.where(name: "Cable fly").count]
    assert Exercise.exists?(@bench.id)
  end

  test "signing up cannot grant admin" do
    post user_registration_path, params: { user: { email: "new@example.com", password: "secret123", password_confirmation: "secret123", admin: true } }
    assert_not User.find_by!(email: "new@example.com").admin?
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

  test "a second workout on the same day only comes from another split" do
    sign_in @user
    split = @user.splits.create!(name: "PPL")
    push = split.workout_days.create!(day: "Push", weekday: 1)
    pull = split.workout_days.create!(day: "Pull", weekday: 3)
    bench = push.workout_exercises.create!(exercise: @bench)
    row = pull.workout_exercises.create!(exercise: Exercise.create!(name: "Barbell row"))
    other_split = @user.splits.create!(name: "Upper lower")
    lower = other_split.workout_days.create!(day: "Lower", weekday: 1)
    squat = lower.workout_exercises.create!(exercise: @squat)

    post workout_exercise_workout_sets_path(bench), params: { workout_set: { reps_completed: 8, weight_used: 60 } }
    assert_equal ["Push"], @user.workout_logs.pluck(:workout)

    # the same split already has today's workout: nothing is logged, and the page says why
    assert_no_difference ["WorkoutLog.count", "WorkoutLogExercise.count", "WorkoutSet.count"] do
      post workout_exercise_workout_sets_path(row), params: { workout_set: { reps_completed: 10, weight_used: 50 } }
    end
    assert_redirected_to workout_exercise_path(row)
    assert_match(/Set not added: Push is already logged on .* in PPL/, flash[:alert])
    # more sets of today's workout are still fine
    post workout_exercise_workout_sets_path(bench), params: { workout_set: { reps_completed: 7, weight_used: 60 } }
    assert_equal 2, WorkoutSet.count

    # another split's workout is a second workout of the day
    post workout_exercise_workout_sets_path(squat), params: { workout_set: { reps_completed: 5, weight_used: 100 } }
    assert_match "Set 1 added", flash[:notice]
    assert_equal %w[Lower Push], @user.workout_logs.where(date: Date.current).pluck(:workout).sort

    # a workout cannot be moved onto a day its split already has a workout on
    earlier = pull.workout_logs.create!(date: Date.current - 7)
    patch workout_log_path(earlier), params: { workout_log: { date: Date.current } }
    assert_match "Push is already logged", flash[:alert]
    assert_equal Date.current - 7, earlier.reload.date
    # its notes can still be edited, and a workout whose split was deleted is not held back
    patch workout_log_path(earlier), params: { workout_log: { notes: "Felt good" } }
    assert_equal "Felt good", earlier.reload.notes
    orphan = @user.workout_logs.create!(workout: "Pull", date: Date.current)
    assert orphan.persisted?
  end

  test "an admin renames an exercise from the workout day" do
    day = @admin.splits.create!(name: "PPL").workout_days.create!(day: "Push", weekday: 1)
    planned = day.workout_exercises.create!(exercise: @bench)
    own = Exercise.create!(name: "Cable fly", user: @user)
    users_day = @user.splits.create!(name: "Mine").workout_days.create!(day: "Push", weekday: 1)
    users_day.workout_exercises.create!(exercise: @bench)
    users_day.workout_exercises.create!(exercise: own)

    # a normal user has no edit button on the day, not even for their own exercise
    sign_in @user
    get workout_day_path(users_day)
    assert_select "a[href^=?]", "/exercises/", count: 0
    patch exercise_path(@bench), params: { exercise: { name: "Hacked" }, workout_day_id: users_day.id }
    assert_response :not_found
    assert_equal "Bench press", @bench.reload.name

    sign_in @admin
    get workout_day_path(day)
    edit = edit_exercise_path(@bench, workout_day_id: day.id)
    assert_select "a[href=?][aria-label=?]", edit, "Edit Bench press"
    # the edit page belongs to the day it was opened from
    get edit
    assert_select ".back-link[href=?]", workout_day_path(day), text: "Push"
    assert_select "input[type=hidden][name=workout_day_id][value=?]", day.id.to_s
    assert_select ".form-actions a[href=?]", workout_day_path(day), text: "Cancel"
    patch exercise_path(@bench), params: { exercise: { name: "" }, workout_day_id: day.id }
    assert_response :unprocessable_entity
    assert_select ".back-link[href=?]", workout_day_path(day)

    patch exercise_path(@bench), params: { exercise: { name: "Barbell bench press" }, workout_day_id: day.id }
    assert_redirected_to workout_day_path(day)
    assert_equal "Barbell bench press", planned.reload.name
    follow_redirect!
    assert_select ".row-title", "Barbell bench press"
    # someone else's day is not a place to go back to
    patch exercise_path(@bench), params: { exercise: { name: "Bench press" }, workout_day_id: users_day.id }
    assert_redirected_to exercises_path
  end
end
