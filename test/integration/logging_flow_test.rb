require "test_helper"

# Planning a day and logging it: exercises, sets, and the one-workout-per-day rules.
class LoggingFlowTest < FlowTest
  test "planning a day's exercises on the split page, from the catalogue or by creating one" do
    sign_in @user
    split = @user.splits.create!(name: "PPL")
    day = split.workout_days.create!(day: "Push", weekday: 1)
    plan = split_path(split, anchor: "day-#{day.id}")
    picker = "#exercise-picker-#{day.id}"
    other_users_exercise = Exercise.create!(name: "Secret lift", muscle_group: "Chest", user: @admin)

    # each day of the split has its card, whose "Plan exercises" opens the catalogue grouped by muscle group
    get split_path(split)
    assert_select "#day-#{day.id} .empty-state", text: /No exercises planned yet/
    assert_select "#day-#{day.id} button[data-bs-target='#{picker}']", text: /Plan exercises/
    assert_equal %w[Chest Legs], css_select("#{picker}-form .picker-group").map(&:text)
    # each muscle group starts closed and opens its exercises
    assert_select "#{picker}-form button.picker-group[aria-expanded=false][data-bs-target='#{picker}-group-chest']", 1
    assert_select "#{picker}-group-chest.collapse:not(.show) label", text: /Bench press/
    assert_select "#{picker} form[action=?]", workout_day_workout_exercises_path(day)
    assert_select "#{picker} label", text: /Bench press/
    assert_select "#{picker} label", text: /Secret lift/, count: 0
    assert_select "#{picker} input[name='exercise[name]']"

    post workout_day_workout_exercises_path(day), params: { exercise_ids: [] }
    assert_match "Choose at least one exercise", flash[:alert]
    post workout_day_workout_exercises_path(day), params: { exercise_ids: [other_users_exercise.id] }
    assert_match "Choose at least one exercise", flash[:alert]
    assert_equal 0, day.workout_exercises.count

    post workout_day_workout_exercises_path(day), params: { exercise_ids: [@bench.id, @squat.id] }
    assert_redirected_to plan
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
    get split_path(split)
    assert_select "#{picker} input[name='exercise[shared]']", 0
    assert_difference "@user.exercises.count", 1 do
      post workout_day_workout_exercises_path(day), params: { exercise: { name: "Cable fly", muscle_group: "Chest" } }
    end
    own = @user.exercises.last
    assert_equal ["Cable fly", "Chest"], [own.name, own.muscle_group]
    assert_equal own, day.workout_exercises.order(:id).last.exercise
    assert_equal 0, Exercise.shared.where(name: "Cable fly").count
    assert_redirected_to plan

    # the day's card lists its exercises; the modal marks them as added and shows the user's own exercise
    get split_path(split)
    assert_select "#day-#{day.id} .list-rows .row-title", text: "Cable fly"
    assert_select "#day-#{day.id} .empty-state", count: 0
    assert_select "#{picker} label.is-taken", 3
    assert_select "#{picker} label", text: /Cable fly.*Yours/m
    # the plan is only which exercises: each can be removed on the spot, and nothing about sets is there
    assert_select "#day-#{day.id} form[action='#{workout_exercise_path(day.workout_exercises.first)}'] button[aria-label='Remove Bench press from Push']"
    assert_select "#day-#{day.id} input[name^='workout_set']", 0

    # other users do not see it, the owner can delete it once it is out of every plan
    get exercises_path
    assert_select "td", text: /Cable fly/
    delete exercise_path(own)
    assert_match "was not deleted", flash[:alert]
    delete workout_exercise_path(day.workout_exercises.find_by!(exercise: own))
    assert_redirected_to plan
    delete exercise_path(own)
    assert_not Exercise.exists?(own.id)

    # an exercise an admin creates in the modal is the admin's own, unless they share it
    sign_out @user
    sign_in @admin
    admin_day = @admin.splits.create!(name: "Admin").workout_days.create!(day: "Legs", weekday: 2)
    get split_path(admin_day.split)
    assert_select "#exercise-picker-#{admin_day.id} input[type=checkbox][name='exercise[shared]']:not([checked])", 1
    post workout_day_workout_exercises_path(admin_day), params: { exercise: { name: "Leg curl", muscle_group: "Legs", shared: "0" } }
    assert_equal @admin, Exercise.find_by!(name: "Leg curl").user
    post workout_day_workout_exercises_path(admin_day), params: { exercise: { name: "Leg extension", muscle_group: "Legs", shared: "1" } }
    assert Exercise.shared.exists?(name: "Leg extension")
    assert_equal ["Leg curl", "Leg extension"], admin_day.workout_exercises.order(:id).pluck(:name)
  end

  test "opening an exercise and adding sets" do
    sign_in @user
    day = @user.splits.create!(name: "PPL").workout_days.create!(day: "Push", weekday: Date.current.wday)
    # the exercise page and its forms carry the date the sets go to
    exercise_page = ->(planned) { workout_exercise_path(planned, date: Date.current) }
    planned = day.workout_exercises.create!(exercise: @bench)

    get workout_exercise_path(planned)
    assert_response :success
    assert_select "h1", "Bench press"
    assert_select "button", text: /Add set/
    assert_select "input[name='workout_set[set_number]']", 0
    assert_equal 0, @user.workout_logs.count

    # an invalid set leaves no empty workout behind
    post workout_exercise_workout_sets_path(planned), params: { workout_set: { reps_completed: "", weight_used: 80 } }
    assert_redirected_to exercise_page.(planned)
    assert_match "Reps completed can't be blank", flash[:alert]
    assert_equal 0, @user.workout_logs.count

    # sets are numbered automatically and go into today's workout
    post workout_exercise_workout_sets_path(planned), params: { workout_set: { reps_completed: 8, weight_used: 80 } }
    assert_redirected_to exercise_page.(planned)
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
    on_exercise_page = workout_set_path(second, workout_exercise_id: planned.id, date: Date.current)
    assert_select "form#edit_set_#{second.id}[action='#{on_exercise_page}']"
    # deleting a set asks first, naming the set and what it held
    assert_select "form.button_to[action='#{on_exercise_page}'][data-turbo-confirm^='Delete set 2? '][data-turbo-confirm$=' reps.']"
    # weight, reps and a note
    assert_select "input[form='edit_set_#{second.id}']", 3
    assert_select "input[form='edit_set_#{second.id}'][name='workout_set[notes]']", 1
    patch on_exercise_page, params: { workout_set: { reps_completed: 5, weight_used: 85.125, notes: "  Paused   reps " } }
    assert_redirected_to exercise_page.(planned)
    assert_equal [2, 5, BigDecimal("85.125"), "Paused reps"],
                 second.reload.then { |s| [s.set_number, s.reps_completed, s.weight_used, s.notes] }
    follow_redirect!
    # the note field is always there, holding the note, and saves itself when changed
    # saving comes back to this page morphed in place, at the same scroll, so it does not jump
    assert_select "meta[name='turbo-refresh-method'][content='morph']"
    assert_select "meta[name='turbo-refresh-scroll'][content='preserve']"
    assert_select "tr.set-note:not([hidden]) input[name='workout_set[notes]'][value='Paused reps'][data-action='change->row-edit#save']"
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
    assert_redirected_to exercise_page.(planned)
    assert_equal 1, entry.workout_sets.count
    post workout_exercise_workout_sets_path(planned), params: { workout_set: { reps_completed: 7 } }
    assert_equal [1, 2], entry.workout_sets.order(:set_number).pluck(:set_number)

    # equipment: free weights, or a machine with a typed brand
    patch workout_exercise_path(planned), params: { workout_exercise: { equipment: "machine", machine_brand: "" } }
    assert_match "Machine brand can't be blank", flash[:alert]
    patch workout_exercise_path(planned), params: { workout_exercise: { equipment: "machine", machine_brand: "Acme" } }
    assert_redirected_to exercise_page.(planned)
    assert_equal "Machine · Acme", planned.reload.equipment_label
    # the sets already recorded today were done on it, so today's entry follows
    assert_equal "Machine · Acme", entry.reload.equipment_label
    patch workout_exercise_path(planned), params: { workout_exercise: { equipment: "free_weights" } }
    assert_nil planned.reload.machine_brand
    assert_equal "Free weights", entry.reload.equipment_label

    get workout_day_path(day)
    assert_select ".chip", text: "2 sets"
    # the workout page does not change the plan: a planned exercise has no remove button there
    assert_select "form[action^='#{workout_exercise_path(planned)}']", 0

    # removing the exercise from the plan (on the split page) keeps what was logged
    delete workout_exercise_path(planned)
    assert_nil entry.reload.workout_exercise
    assert_equal 2, entry.workout_sets.count
  end

  test "a workout day logs on its date this week: an earlier day fills that day in, a day to come takes no sets" do
    sign_in @user
    split = @user.splits.create!(name: "Upper lower")
    lower = split.workout_days.create!(day: "Lower", weekday: 3)
    upper = split.workout_days.create!(day: "Upper", weekday: 5)
    squat = lower.workout_exercises.create!(exercise: @squat)
    bench = upper.workout_exercises.create!(exercise: @bench)
    wednesday = Date.new(2026, 11, 18)

    # Thursday: Wednesday's Lower was trained but not logged
    travel_to Time.zone.local(2026, 11, 19, 12) do
      get workout_day_path(lower)
      assert_select ".page-header p", "Wednesday, November 18"
      assert_select ".list-rows a.row-link[href=?]", workout_exercise_path(squat, date: wednesday)
      get workout_exercise_path(squat)
      assert_select ".card-header h2", "Wednesday"
      assert_select "form.set-form[action=?]", workout_exercise_workout_sets_path(squat, date: wednesday)

      post workout_exercise_workout_sets_path(squat, date: wednesday), params: { workout_set: { reps_completed: 5, weight_used: 100 } }
      assert_redirected_to workout_exercise_path(squat, date: wednesday)
      # a page opened without a date uses the same day
      post workout_exercise_workout_sets_path(squat), params: { workout_set: { reps_completed: 4, weight_used: 105 } }
      log = @user.workout_logs.sole
      assert_equal [wednesday, false], [log.date, log.rest_day?]
      assert_equal 2, WorkoutSet.count
      get workout_day_path(lower)
      assert_select ".chip-done", "2 sets"

      # Friday's Upper is planned, not done: no form, and a set sent anyway is refused
      get workout_exercise_path(bench)
      assert_select ".card-header h2", "Friday"
      assert_select ".empty-state", /Upper is on Friday this week. Add sets on that day./
      assert_select "form.set-form", 0
      assert_no_difference ["WorkoutLog.count", "WorkoutSet.count"] do
        post workout_exercise_workout_sets_path(bench), params: { workout_set: { reps_completed: 8, weight_used: 60 } }
      end
      assert_match "Set not added: Date can't be in the future", flash[:alert]
      # the plan itself can still be filled in ahead of the day
      post workout_day_workout_exercises_path(upper), params: { exercise_ids: [@squat.id] }
      assert_equal 2, upper.workout_exercises.count

      # a date that is not one opens the day of this week
      get workout_exercise_path(squat, date: "yesterday")
      assert_select ".card-header h2", "Wednesday"
    end

    # a set added after midnight from a page opened before it stays on the day the workout started
    travel_to Time.zone.local(2026, 11, 20, 0, 30) do
      post workout_exercise_workout_sets_path(squat, date: wednesday), params: { workout_set: { reps_completed: 3, weight_used: 110 } }
      assert_equal [wednesday], @user.workout_logs.pluck(:date)
      assert_equal 3, WorkoutSet.count
    end
  end

  test "an exercise added while training goes into that workout, never into the plan" do
    sign_in @user
    split = @user.splits.create!(name: "PPL")
    day = split.workout_days.create!(day: "Push", weekday: Date.current.wday)
    planned = day.workout_exercises.create!(exercise: @bench)
    today = Date.current
    page = workout_day_path(day, date: today)

    # the workout page offers "Add exercise", which posts to the workout, not to the plan
    get page
    assert_select "#exercise-picker form[action=?]", workout_day_workout_log_exercises_path(day, date: today)
    assert_select "#exercise-picker label.is-taken", 1

    # the first exercise added starts the session; the plan keeps only Bench press
    post workout_day_workout_log_exercises_path(day, date: today), params: { exercise_ids: [@squat.id] }
    assert_redirected_to page
    assert_equal "Squat added to this workout.", flash[:notice]
    log = @user.workout_logs.sole
    assert_equal [day, today, "Push"], [log.workout_day, log.date, log.workout]
    assert_equal ["Squat"], log.workout_log_exercises.pluck(:name)
    assert_equal [planned], day.workout_exercises.to_a
    # one created on the spot joins the same session
    post workout_day_workout_log_exercises_path(day, date: today), params: { exercise: { name: "Dips", muscle_group: "Triceps" } }
    assert_equal %w[Squat Dips], log.workout_log_exercises.order(:id).pluck(:name)
    assert_equal [planned], day.workout_exercises.to_a
    # it is in the workout once
    post workout_day_workout_log_exercises_path(day, date: today), params: { exercise_ids: [@squat.id] }
    assert_match "Squat is already in this workout", flash[:alert]

    # the workout page lists the workout first (what was added, which opens in the logged workout),
    # then the plan still to do
    get page
    assert_equal ["Squat", "Dips", "Bench press"], css_select(".list-rows .row-title").map(&:text)
    squat_entry = log.workout_log_exercises.find_by!(name: "Squat")
    assert_select ".list-rows a.row-link[href=?]", workout_log_path(log, anchor: "entry-#{squat_entry.id}")
    assert_select "#exercise-picker label.is-taken", 3
    # the logged workout offers only what is planned and not in it yet
    get workout_log_path(log)
    assert_equal ["Bench press"], css_select(".list-rows .row-title").map(&:text)

    # removing an added exercise from the workout page takes it out of the workout, and it is gone
    delete workout_log_exercise_path(squat_entry, workout_day_id: day.id, date: today)
    assert_redirected_to page
    assert_equal ["Dips"], log.workout_log_exercises.pluck(:name)
    assert_equal [planned], day.workout_exercises.to_a
    get page
    assert_select ".list-rows .row-title", text: "Squat", count: 0

    # a workout later this week (Friday's, on a Thursday) takes nothing yet
    later = @user.splits.create!(name: "Later").workout_days.create!(day: "Pull", weekday: 5)
    travel_to Time.zone.local(2026, 11, 19, 12) do
      get workout_day_path(later)
      assert_select "#exercise-picker", 0
      assert_no_difference ["WorkoutLog.count", "WorkoutLogExercise.count"] do
        post workout_day_workout_log_exercises_path(later), params: { exercise_ids: [@squat.id] }
      end
      assert_match "Date can't be in the future", flash[:alert]
    end
  end

  test "a logged workout can be reviewed and corrected" do
    sign_in @user
    day = @user.splits.create!(name: "PPL").workout_days.create!(day: "Push", weekday: Date.current.wday)
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
    # each exercise is folded: its name, sets and heaviest set, and an arrow that opens the rest
    card = "#entry-#{entry.id}[data-controller=fold]"
    assert_select "#{card} .card-header .top-set", "80 kg × 8 reps"
    assert_select "#{card} .card-header .chip", "1 set"
    assert_select "#{card} button.entry-toggle[aria-expanded=false][data-bs-target='#entry-#{entry.id}-sets']", 1
    assert_select "#entry-#{entry.id}-sets.collapse:not(.show) table.set-table", 1
    assert_select "#entry-#{entry.id}-sets.collapse:not(.show) form[action=?]", workout_log_exercise_workout_sets_path(entry)
    # edit and remove are in its ⋯ menu; removing is an ×
    assert_select "#{card} .card-header .actions-menu .dropdown-menu a[href=?]", edit_workout_log_exercise_path(entry), text: /Edit/
    assert_select "#{card} .card-header .actions-menu form.button_to[action=?][data-turbo-confirm] .fa-xmark", workout_log_exercise_path(entry)
    # a set's edit and delete are in its own ⋯ menu, and delete is an × there too
    assert_select ".set-table .actions-menu button[data-action='row-edit#edit']", 1
    assert_select ".set-table .actions-menu form.button_to .fa-xmark", 1
    assert_select ".fa-trash", 0

    post workout_log_exercise_workout_sets_path(entry), params: { workout_set: { reps_completed: 8 } }
    assert_equal [1, 2], entry.workout_sets.order(:set_number).pluck(:set_number)
    # a set is numbered by the app: a number sent with the form is ignored
    post workout_log_exercise_workout_sets_path(entry), params: { workout_set: { set_number: 1, reps_completed: 8 } }
    assert_equal [1, 2, 3], entry.workout_sets.order(:set_number).pluck(:set_number)

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
    assert_response :unprocessable_content
    patch workout_log_exercise_path(entry), params: { workout_log_exercise: { equipment: "machine", machine_brand: "Beta", notes: "Left shoulder tight" } }
    assert_equal ["Machine · Beta", "Left shoulder tight"], entry.reload.then { |e| [e.equipment_label, e.notes] }
    assert_equal "free_weights", planned.reload.equipment

    get workout_log_path(log)
    assert_response :success
    assert_select "p", /Machine · Beta/
    assert_select "p.entry-note", /Left shoulder tight/

    # removing a planned exercise from the workout keeps it on the day, where it is offered again;
    # one that was not planned is simply gone
    delete workout_log_exercise_path(entry)
    delete workout_log_exercise_path(log.workout_log_exercises.find_by!(name: "Dips"))
    assert_equal ["Squat"], log.workout_log_exercises.pluck(:name)
    assert_equal [planned, unused], day.workout_exercises.order(:id).to_a
    get workout_log_path(log)
    assert_select "h2", "From this day, not in this workout"
    assert_select "ul.list-rows .row-title", text: "Bench press"
    assert_select "ul.list-rows .row-title", text: "Dips", count: 0
    delete workout_log_path(log)
    assert_redirected_to workout_logs_path
    assert_equal 0, @user.workout_logs.count
  end

  test "the same workout from two splits on one day is one logged workout" do
    sign_in @user
    ppl = @user.splits.create!(name: "PPL").workout_days.create!(day: "Legs", weekday: Date.current.wday)
    upper_lower = @user.splits.create!(name: "Upper lower").workout_days.create!(day: "Lower", weekday: Date.current.wday)
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

  test "a second workout on the same day only comes from another split" do
    sign_in @user
    split = @user.splits.create!(name: "PPL")
    push = split.workout_days.create!(day: "Push", weekday: Date.current.wday)
    pull = split.workout_days.create!(day: "Pull", weekday: (Date.current.wday + 1) % 7)
    bench = push.workout_exercises.create!(exercise: @bench)
    row = pull.workout_exercises.create!(exercise: Exercise.create!(name: "Barbell row"))
    other_split = @user.splits.create!(name: "Upper lower")
    lower = other_split.workout_days.create!(day: "Lower", weekday: Date.current.wday)
    squat = lower.workout_exercises.create!(exercise: @squat)

    post workout_exercise_workout_sets_path(bench), params: { workout_set: { reps_completed: 8, weight_used: 60 } }
    assert_equal ["Push"], @user.workout_logs.pluck(:workout)

    # the same split already has today's workout: Pull trained today as well (opened with today's
    # date, as "Train as extra" does) logs nothing, and the page says why
    assert_no_difference ["WorkoutLog.count", "WorkoutLogExercise.count", "WorkoutSet.count"] do
      post workout_exercise_workout_sets_path(row, date: Date.current), params: { workout_set: { reps_completed: 10, weight_used: 50 } }
    end
    assert_redirected_to workout_exercise_path(row, date: Date.current)
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

  test "the add-set form is the same on the exercise page and on the logged workout page" do
    sign_in @user
    day = @user.splits.create!(name: "PPL").workout_days.create!(day: "Push", weekday: Date.current.wday)
    planned = day.workout_exercises.create!(exercise: @bench)
    entry = planned.entry_on!(Date.current)

    [workout_exercise_path(planned), workout_log_path(entry.workout_log)].each do |path|
      get path
      assert_select "input[name='workout_set[weight_used]'][min='0'][inputmode='decimal'][step='any']", { minimum: 1 }, path
      assert_select "input[name='workout_set[reps_completed]'][min='0'][inputmode='numeric'][required]", { minimum: 1 }, path
    end
  end

  test "names and notes have a length limit" do
    sign_in @user
    post splits_path, params: { split: { name: "x" * 61 } }
    assert_response :unprocessable_content

    day = @user.splits.create!(name: "PPL").workout_days.create!(day: "Push", weekday: Date.current.wday)
    entry = day.workout_exercises.create!(exercise: @bench).entry_on!(Date.current)
    post workout_log_exercise_workout_sets_path(entry), params: { workout_set: { reps_completed: 8, notes: "x" * 201 } }
    assert_match "Notes is too long", flash[:alert]
    assert_empty entry.workout_sets

    patch workout_log_path(entry.workout_log), params: { workout_log: { notes: "x" * 2001 } }
    assert_match "Notes is too long", flash[:alert]
  end

  test "a reps number that is too large is refused with a message, not an error page" do
    sign_in @user
    day = @user.splits.create!(name: "PPL").workout_days.create!(day: "Push", weekday: Date.current.wday)
    planned = day.workout_exercises.create!(exercise: @bench)

    ["99999999999999", (WorkoutSet::MAX_REPS + 1).to_s].each do |reps|
      assert_no_difference -> { WorkoutSet.count } do
        post workout_exercise_workout_sets_path(planned), params: { workout_set: { reps_completed: reps, weight_used: 60 } }
      end
      assert_redirected_to workout_exercise_path(planned, date: Date.current)
      assert_match "Reps completed must be less than or equal to #{WorkoutSet::MAX_REPS}", flash[:alert]
    end
    # the refused set did not leave an empty workout behind
    assert_equal 0, @user.workout_logs.count

    post workout_exercise_workout_sets_path(planned), params: { workout_set: { reps_completed: 8, weight_used: 60 } }
    set = @user.workout_sets.sole
    patch workout_set_path(set), params: { workout_set: { reps_completed: "99999999999999" } }
    assert_match "Set not updated", flash[:alert]
    assert_equal 8, set.reload.reps_completed
  end

  test "a workout's date cannot be moved to the future or to a year no page shows" do
    sign_in @user
    log = @user.splits.create!(name: "PPL").workout_days.create!(day: "Push", weekday: 1)
               .workout_logs.create!(date: Date.current - 1)
    # the date picker offers only the days the rule allows
    get workout_log_path(log)
    assert_select "input[name='workout_log[date]'][min='2000-01-01'][max=?]", Date.current.iso8601

    { (Date.current + 1).iso8601 => "Date can't be in the future",
      "0001-01-01" => "Date can't be before 2000",
      "99999-01-01" => "Date can't be in the future" }.each do |date, message|
      patch workout_log_path(log), params: { workout_log: { date: } }
      assert_redirected_to workout_log_path(log)
      assert_match message, flash[:alert]
    end
    assert_equal Date.current - 1, log.reload.date
  end

  test "bodyweight is an equipment: its sets add weight to the body or take it off" do
    sign_in @user
    pull_up = Exercise.create!(name: "Pull-up", muscle_group: "Back")
    day = @user.splits.create!(name: "PPL").workout_days.create!(day: "Pull", weekday: Date.current.wday)
    planned = day.workout_exercises.create!(exercise: pull_up)
    page = workout_exercise_path(planned, date: Date.current)

    # chosen like the others, on the exercise page
    get page
    assert_select "input[type=radio][name='workout_exercise[equipment]'][value=bodyweight]", 1
    patch workout_exercise_path(planned, date: Date.current), params: { workout_exercise: { equipment: "bodyweight" } }
    assert_equal "Bodyweight", planned.reload.equipment_label

    # the weight field takes a sign, with a ± for a phone's keypad, which has no minus key
    get page
    assert_select "label[for='weight_workout_exercise_#{planned.id}']", text: /Bodyweight\s*BW ± kg/
    assert_select ".input-group[data-controller=sign] button[data-action='sign#flip']", "±"
    assert_select "input#weight_workout_exercise_#{planned.id}[data-sign-target=input]:not([min])", 1

    post workout_exercise_workout_sets_path(planned, date: Date.current), params: { workout_set: { reps_completed: 8, weight_used: 10 } }
    post workout_exercise_workout_sets_path(planned, date: Date.current), params: { workout_set: { reps_completed: 6, weight_used: -15.5 } }
    post workout_exercise_workout_sets_path(planned, date: Date.current), params: { workout_set: { reps_completed: 10, weight_used: "" } }
    entry = planned.entry_on(Date.current)
    assert entry.bodyweight?
    assert_equal [10, -15.5, nil], entry.workout_sets.order(:set_number).pluck(:weight_used)

    # shown as "Bodyweight + 10 kg", with "BW" in place of "Bodyweight" on a phone
    get page
    assert_equal ["Bodyweight BW + 10 kg", "Bodyweight BW − 15.5 kg", "Bodyweight BW"],
                 css_select(".set-table td:nth-child(2) > span[data-row-edit-target=view]").map { |n| n.children.map(&:text).join(" ").squish }
    assert_select ".set-table td > span .d-sm-none", %w[BW BW BW].size
    # a confirm is a sentence: the long words only
    second = entry.workout_sets.find_by!(set_number: 2)
    assert_select "form[data-turbo-confirm=?]", "Delete set 2? Bodyweight − 15.5 kg × 6 reps."
    # a set being corrected keeps its sign and its ±
    assert_select ".input-group.set-field[data-controller=sign][hidden] input[form='edit_set_#{second.id}'][value='-15.5']", 1

    # a weight below zero is only for bodyweight
    bench = day.workout_exercises.create!(exercise: @bench)
    post workout_exercise_workout_sets_path(bench, date: Date.current), params: { workout_set: { reps_completed: 5, weight_used: -5 } }
    assert_match "Weight used must be greater than or equal to 0", flash[:alert]
    get workout_exercise_path(bench, date: Date.current)
    assert_select "input#weight_workout_exercise_#{bench.id}[min='0']", 1
    assert_select ".input-group[data-controller=sign]", 0
  end
end
