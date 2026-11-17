require "test_helper"

# Planning a day and logging it: exercises, sets, and the one-workout-per-day rules.
class LoggingFlowTest < FlowTest
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

    delete workout_log_exercise_path(entry)
    assert_equal 2, log.workout_log_exercises.count
    delete workout_log_path(log)
    assert_redirected_to workout_logs_path
    assert_equal 0, @user.workout_logs.count
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
      assert_redirected_to workout_exercise_path(planned)
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
end

