require "test_helper"

# Cardio: an exercise of the catalogue's Cardio group, logged as rows of incline, speed and time
# instead of sets of weight and reps.
class CardioFlowTest < FlowTest
  setup do
    @treadmill = Exercise.create!(name: "Treadmill", muscle_group: "Cardio")
    @day = @user.splits.create!(name: "PPL").workout_days.create!(day: "Push", weekday: Date.current.wday)
  end

  test "cardio is a group of the catalogue, and a new exercise can be cardio" do
    sign_in @user
    page = workout_day_path(@day, date: Date.current)
    get page
    assert_select "#exercise-picker .picker-group .group-name", "Cardio"
    assert_select "#exercise-picker-group-cardio .picker-name", "Treadmill"
    # the new exercise form offers Cardio beside the muscle groups
    assert_select "#exercise-picker input[name='exercise[muscle_group]'][value='Cardio']"

    post workout_day_workout_log_exercises_path(@day, date: Date.current),
         params: { exercise: { name: "Rowing machine", muscle_group: "Cardio" } }
    assert_redirected_to page
    assert Exercise.find_by!(name: "Rowing machine", user: @user).cardio?
    assert_not @bench.cardio?
  end

  test "a cardio exercise's page logs incline, speed and time, not weight and reps" do
    sign_in @user
    planned = @day.workout_exercises.create!(exercise: @treadmill)
    page = workout_exercise_path(planned, date: Date.current)

    get page
    assert_response :success
    assert_select "h1", "Treadmill"
    assert_select "input[name='cardio_entry[incline]']"
    assert_select "input[name='cardio_entry[speed]']"
    assert_select "input[name='cardio_entry[minutes]']"
    assert_select "input[name='cardio_entry[seconds]']"
    # nothing of a lift: no weight, reps, equipment or rest timer
    assert_select "input[name='workout_set[weight_used]']", 0
    assert_select "input[name='workout_set[reps_completed]']", 0
    assert_select "h2", text: "Equipment", count: 0
    assert_select "[data-controller~='rest-alert']", 0

    # the first row starts today's workout, as a first set does
    post workout_exercise_cardio_entries_path(planned, date: Date.current),
         params: { cardio_entry: { incline: "5", speed: "6.0", minutes: "12", seconds: "30" } }
    assert_redirected_to page
    entry = @user.workout_logs.sole.workout_log_exercises.sole
    assert_equal planned, entry.workout_exercise

    follow_redirect!
    assert_select "table.cardio-table tbody tr", 1
    assert_select "table.cardio-table td", text: "5 %"
    assert_select "table.cardio-table td", text: "6 km/h"
    assert_select "table.cardio-table td", text: "12:30"
    # the next row starts from the last one
    assert_select "input[name='cardio_entry[incline]'][value='5']"
    assert_select "input[name='cardio_entry[minutes]'][value='12']"

    # only the time is needed: a bike has no incline
    post workout_exercise_cardio_entries_path(planned, date: Date.current), params: { cardio_entry: { minutes: "20", seconds: "" } }
    follow_redirect!
    assert_select "table.cardio-table tbody tr", 2
    assert_select "table.cardio-table td", text: "20:00"
  end

  test "a cardio row without a time is refused and leaves no workout behind" do
    sign_in @user
    planned = @day.workout_exercises.create!(exercise: @treadmill)
    post workout_exercise_cardio_entries_path(planned, date: Date.current),
         params: { cardio_entry: { incline: "5", speed: "6", minutes: "", seconds: "" } }
    assert_redirected_to workout_exercise_path(planned, date: Date.current)
    assert_match "Time", flash[:alert]
    assert_equal 0, @user.workout_logs.count

    # nor on a day still to come
    later = @user.splits.first.workout_days.create!(day: "Pull", weekday: (Date.current + 1).wday)
    upcoming = later.workout_exercises.create!(exercise: @treadmill)
    post workout_exercise_cardio_entries_path(upcoming, date: Date.current + 1), params: { cardio_entry: { minutes: "10" } }
    assert flash[:alert].present?
    assert_equal 0, @user.workout_logs.count
  end

  test "on a logged workout cardio rows are added, corrected and deleted" do
    sign_in @user
    log = @user.workout_logs.create!(workout: "Push", date: Date.current)
    bench = log.workout_log_exercises.create!(exercise: @bench)
    treadmill = log.workout_log_exercises.create!(exercise: @treadmill)
    page = workout_log_path(log, anchor: "entry-#{treadmill.id}")

    get workout_log_path(log)
    # the treadmill's card has the cardio form, the bench press's the set form
    assert_select "#entry-#{treadmill.id} input[name='cardio_entry[minutes]']"
    assert_select "#entry-#{treadmill.id} input[name='workout_set[reps_completed]']", 0
    assert_select "#entry-#{bench.id} input[name='workout_set[reps_completed]']"
    assert_select "#entry-#{bench.id} input[name='cardio_entry[minutes]']", 0

    post workout_log_exercise_cardio_entries_path(treadmill), params: { cardio_entry: { incline: "8", speed: "5.5", minutes: "30", seconds: "0" } }
    assert_redirected_to page
    follow_redirect!
    assert_select "#entry-#{treadmill.id} table.cardio-table td", text: "30:00"
    assert_select "#entry-#{treadmill.id} .chip", text: "30 min"
    row = treadmill.cardio_entries.sole

    # corrected in place
    patch cardio_entry_path(row), params: { cardio_entry: { incline: "10", speed: "5.5", minutes: "32", seconds: "15" } }
    assert_redirected_to page
    follow_redirect!
    assert_select "#entry-#{treadmill.id} table.cardio-table td", text: "10 %"
    assert_select "#entry-#{treadmill.id} table.cardio-table td", text: "32:15"

    # no one else's rows (a 404 does not persist the test session, so sign in before each request)
    sign_in @admin
    patch cardio_entry_path(row), params: { cardio_entry: { minutes: "1" } }
    assert_response :not_found
    sign_in @admin
    delete cardio_entry_path(row)
    assert_response :not_found
    sign_in @admin
    post workout_log_exercise_cardio_entries_path(treadmill), params: { cardio_entry: { minutes: "1" } }
    assert_response :not_found
    assert_equal 1935, row.reload.duration_seconds

    # its Edit (the card's ⋯ menu) keeps the note, with no equipment to choose
    sign_in @user
    get edit_workout_log_exercise_path(treadmill)
    assert_select "textarea[name='workout_log_exercise[notes]']"
    assert_select "[name='workout_log_exercise[equipment]']", 0

    delete cardio_entry_path(row)
    assert_redirected_to page
    follow_redirect!
    assert_select "#entry-#{treadmill.id} table.cardio-table", 0
  end

  # A workout with its exercises (name => sets of [reps, weight]) and cardio (name => rows of seconds).
  def log_workout(workout, date, lifts: {}, cardio: {})
    log = @user.workout_logs.create!(workout:, date:)
    lifts.each do |exercise, sets|
      entry = log.workout_log_exercises.create!(exercise:)
      sets.each { |reps, weight| entry.workout_sets.create!(reps_completed: reps, weight_used: weight) }
    end
    cardio.each do |exercise, rows|
      entry = log.workout_log_exercises.create!(exercise:)
      rows.each { |seconds| entry.cardio_entries.create!(duration_seconds: seconds) }
    end
    log
  end

  # Noon on a day the split has nothing on, so a rest day: Wednesday 2026-11-18, or the Thursday when
  # the split's Push (set up on the weekday the test runs) falls on a Wednesday.
  def rest_day_noon
    Time.zone.local(2026, 11, @day.weekday == 3 ? 19 : 18, 12)
  end

  test "cardio counts as an exercise, with its time where the sets are" do
    travel_to rest_day_noon do
      sign_in @user
      log = log_workout("Pull", Date.current, cardio: { @treadmill => [1200, 600] })

      get root_path
      assert_select ".today", /Logged today · Pull, 30 min/

      get root_path
      assert_select ".week-summary div", text: /Cardio\s*30 min/
      assert_select ".week-overview-days li.has-workout .small", "1 exercise · 30 min"
      assert_select "#recent-log-#{log.id} .recent-counts", "1 exercise · 30 min"
      assert_select "#recent-log-#{log.id} .top-set", text: /30 min/

      get workout_logs_path
      assert_select ".history-counts", text: "1 exercise · 30 min"
    end
  end

  test "on a rest day the Today box has its own Cardio button" do
    cardio = new_workout_log_path(workout: "Cardio")
    travel_to rest_day_noon do
      sign_in @user
      get root_path
      assert_select ".today .today-header a[href=?]", cardio, text: /Cardio/
      get root_path
      assert_select ".today .today-header a[href=?]", cardio, text: /Cardio/

      # once today's Cardio workout is started, the button says it goes back to it
      post workout_logs_path(workout: "Cardio"), params: { exercise_ids: [@treadmill.id] }
      get root_path
      assert_select ".today .today-header a[href=?]", cardio, text: "Continue cardio"
    end

    # on the split's own training day there is none
    sign_in @user
    get root_path
    assert_select ".today a[href=?]", cardio, 0
  end

  test "the Cardio workout offers only cardio, and one created there is cardio" do
    travel_to Time.zone.local(2026, 11, 18, 12) do
      sign_in @user
      get new_workout_log_path(workout: "Cardio")
      assert_response :success
      assert_select "h1", "Cardio workout"
      assert_select "#exercise-picker .picker-name", "Treadmill"
      assert_select "#exercise-picker .picker-group .group-name", "Cardio"
      # the create form asks only the name: no muscle groups, equipment or one-sided
      assert_select "#exercise-picker input[type=radio][name='exercise[muscle_group]']", 0
      assert_select "#exercise-picker input[type=hidden][name='exercise[muscle_group]'][value='Cardio']"
      assert_select "#exercise-picker .equipment-fields", 0
      assert_select "#exercise-picker [name='exercise[unilateral]']", 0
    end
  end

  test "the Cardio workout is started by its first cardio exercise, as a rest day workout" do
    travel_to rest_day_noon do
      sign_in @user
      # a weight exercise sent along is left out
      post workout_logs_path(workout: "Cardio"), params: { exercise_ids: [@treadmill.id, @bench.id] }
      log = @user.workout_logs.sole
      assert_redirected_to workout_log_path(log, from: "dashboard")
      assert_equal ["Cardio", Date.current, true, nil], [log.workout, log.date, log.rest_day?, log.workout_day]
      assert_equal ["Treadmill"], log.workout_log_exercises.map(&:name)

      # the button again opens that workout
      get new_workout_log_path(workout: "Cardio")
      assert_redirected_to workout_log_path(log, from: "dashboard")

      # its page adds only cardio, and one typed there is cardio
      get workout_log_path(log)
      assert_select "#exercise-picker .picker-name", "Treadmill"
      assert_select "#exercise-picker input[type=hidden][name='exercise[muscle_group]'][value='Cardio']"
      post workout_log_workout_log_exercises_path(log), params: { exercise_ids: [@bench.id] }
      assert_equal ["Treadmill"], log.workout_log_exercises.reload.map(&:name)
      post workout_log_workout_log_exercises_path(log), params: { exercise: { name: "Jump rope", muscle_group: "Legs" } }
      assert @user.exercises.find_by!(name: "Jump rope").cardio?
      assert_equal %w[Treadmill Jump\ rope], log.workout_log_exercises.reload.map(&:name)
    end
  end

  test "the cardio timer starts the workout, fills the form on Stop, and Add saves it" do
    sign_in @user
    planned = @day.workout_exercises.create!(exercise: @treadmill)
    page = workout_exercise_path(planned, date: Date.current)

    get page
    assert_select "form[action^='#{workout_exercise_rest_path(planned)}'] button", /Start cardio timer/
    # or the form by hand: folded behind its own button until it is tapped
    assert_select "button[data-bs-target='#cardio-form-workout_exercise-#{planned.id}']", /Add manually/
    assert_select "#cardio-form-workout_exercise-#{planned.id}.collapse:not(.show) input[name='cardio_entry[minutes]']"
    assert_equal 0, @user.workout_logs.count

    # Start logs today's workout and the exercise, as a first row would. The clock is frozen so the
    # seconds between Start and Stop are exact (travel_to cuts off the fraction of a second).
    freeze_time
    post workout_exercise_rest_path(planned, date: Date.current)
    assert_redirected_to page
    entry = @user.workout_logs.sole.workout_log_exercises.sole
    assert_equal planned, entry.workout_exercise
    assert entry.rest_running?

    # while it runs the incline and speed can be filled in (not the time), and leaving asks about a cardio timer
    follow_redirect!
    assert_select "[data-rest-running][data-rest-name='cardio']", 1
    assert_select "[data-controller~='rest-alert']", 1
    assert_select "#cardio-form-workout_exercise-#{planned.id}.show input[name='cardio_entry[incline]']"
    assert_select "input[name='cardio_entry[minutes]']", 0
    assert_select "button", text: /Add manually/, count: 0

    travel 12.minutes + 3.seconds do
      patch workout_log_exercise_rest_path(entry, workout_exercise_id: planned.id, date: Date.current)
      assert_redirected_to page
    end
    assert_equal 723, entry.reload.timer_seconds
    unfreeze_time

    # the stopped time is in the form; the incline and speed are still to give
    get page
    assert_select "input[name='cardio_entry[minutes]'][value='12']"
    assert_select "input[name='cardio_entry[seconds]'][value='03']"
    post workout_exercise_cardio_entries_path(planned, date: Date.current),
         params: { cardio_entry: { incline: "4", speed: "6.5", minutes: "12", seconds: "03" } }
    assert_equal 723, entry.cardio_entries.sole.duration_seconds
    assert_nil entry.reload.rest_started_at
    assert_nil entry.rest_ended_at
  end

  test "adding while the timer runs stops it and saves its time with the incline and speed" do
    sign_in @user
    planned = @day.workout_exercises.create!(exercise: @treadmill)
    freeze_time
    post workout_exercise_rest_path(planned, date: Date.current)
    entry = @user.workout_log_exercises.sole

    travel 90.seconds do
      post workout_exercise_cardio_entries_path(planned, date: Date.current), params: { cardio_entry: { incline: "3", speed: "7" } }
    end
    row = entry.cardio_entries.sole
    assert_equal [90, 3, 7], [row.duration_seconds, row.incline, row.speed]
    unfreeze_time
    assert_nil entry.reload.rest_started_at
  end

  test "a Cardio workout opens its first exercise, and a timed cardio exercise stays open" do
    sign_in @user
    log = @user.workout_logs.create!(workout: WorkoutLog::CARDIO, date: Date.current)
    first = log.workout_log_exercises.create!(exercise: @treadmill)
    second = log.workout_log_exercises.create!(exercise: Exercise.create!(name: "Rower", muscle_group: "Cardio"))
    get workout_log_path(log)
    assert_select "#entry-#{first.id}-sets.show"
    assert_select "#entry-#{second.id}-sets.show", 0

    second.update!(rest_started_at: Time.current)
    get workout_log_path(log)
    assert_select "#entry-#{second.id}-sets.show"
  end

  test "a time typed over the timer's is the one saved, and the timer can be thrown away" do
    sign_in @user
    planned = @day.workout_exercises.create!(exercise: @treadmill)
    post workout_exercise_rest_path(planned, date: Date.current)
    entry = @user.workout_log_exercises.sole
    travel(5.minutes) { patch workout_log_exercise_rest_path(entry, workout_exercise_id: planned.id, date: Date.current) }

    post workout_exercise_cardio_entries_path(planned, date: Date.current), params: { cardio_entry: { minutes: "20", seconds: "" } }
    assert_equal 1200, entry.cardio_entries.sole.duration_seconds

    post workout_exercise_rest_path(planned, date: Date.current)
    delete workout_log_exercise_rest_path(entry, workout_exercise_id: planned.id, date: Date.current)
    assert_nil entry.reload.rest_started_at
  end

  test "the cardio timer does not start on a day to come or on an earlier day" do
    sign_in @user
    later = @user.splits.first.workout_days.create!(day: "Pull", weekday: (Date.current + 1).wday)
    upcoming = later.workout_exercises.create!(exercise: @treadmill)
    post workout_exercise_rest_path(upcoming, date: Date.current + 1)
    assert_redirected_to workout_exercise_path(upcoming, date: Date.current + 1)
    assert_match "Timer not started", flash[:alert]
    assert_equal 0, @user.workout_logs.count

    # an earlier day offers no Start, only typing
    planned = @day.workout_exercises.create!(exercise: @treadmill)
    get workout_exercise_path(planned, date: Date.current - 7)
    assert_select ".cardio-timer", 0
    assert_select ".collapse.show input[name='cardio_entry[minutes]']"
  end

  test "a Cardio workout has no workout timer, each cardio exercise has its own" do
    sign_in @user
    log = @user.workout_logs.create!(workout: WorkoutLog::CARDIO, date: Date.current)
    entry = log.workout_log_exercises.create!(exercise: @treadmill)

    get workout_log_path(log)
    assert_select ".timer-card", 0
    assert_select "form[action='#{workout_log_exercise_rest_path(entry)}'] button", /Start cardio timer/

    # other workouts keep theirs
    lifting = @day.workout_logs.create!(date: Date.current)
    lifting.workout_log_exercises.create!(exercise: @treadmill)
    get workout_log_path(lifting)
    assert_select ".timer-card"
    assert_select ".cardio-timer"
  end

  test "lifting and cardio on the same day add up" do
    # a Monday, the split's Push day
    travel_to Time.zone.local(2026, 11, 16, 12) do
      sign_in @user
      day = @user.splits.create!(name: "Mondays").workout_days.create!(day: "Push", weekday: 1)
      @user.update!(active_split: day.split)
      log = day.workout_logs.create!(date: Date.current)
      log.workout_log_exercises.create!(exercise: @bench).workout_sets.create!(reps_completed: 8, weight_used: 80)
      log.workout_log_exercises.create!(exercise: @treadmill).cardio_entries.create!(duration_seconds: 1800)

      get root_path
      assert_select ".today", /Logged today · 2 exercises · 1 set · 30 min · top 80 kg/
      assert_select ".today a", "Continue"
      assert_select ".today .top-set", text: /30 min/

      get workout_day_path(day, date: Date.current)
      assert_select ".page-header .day-counts", "2 exercises · 1 set · 30 min"
      # the treadmill was added while training: its chip shows its time
      assert_select ".day-in-workout .chip-done", text: "30 min"
      assert_select ".day-in-workout .text-muted", text: /Cardio · Added to this workout/

      get root_path
      assert_equal ["1", "2", "1", "80 kg", "30 min"], css_select(".week-summary dd").map { |n| n.text.squish }
    end
  end
end
