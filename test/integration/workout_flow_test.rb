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

    # creating an exercise makes it the user's own and adds it to the day
    post workout_day_workout_exercises_path(day), params: { exercise: { name: "", muscle_group: "Chest" } }
    assert_match "Name can't be blank", flash[:alert]
    assert_difference "@user.exercises.count", 1 do
      post workout_day_workout_exercises_path(day), params: { exercise: { name: "Cable fly", muscle_group: "Chest" } }
    end
    own = @user.exercises.last
    assert_equal ["Cable fly", "Chest"], [own.name, own.muscle_group]
    assert_equal own, day.workout_exercises.order(:id).last.exercise
    assert_equal 0, Exercise.shared.where(name: "Cable fly").count

    # the day lists its exercises; the modal marks them as added and shows the user's own exercise
    get workout_day_path(day)
    assert_select ".list-rows .row-title", text: "Cable fly"
    assert_select ".empty-state", text: /No exercises for this day/, count: 0
    assert_select "#exercise-picker label.is-taken", 3
    assert_select "#exercise-picker label", text: /Cable fly.*Yours/m

    # other users do not see it, the owner can delete it once it is out of every plan
    get exercises_path
    assert_select "td", text: /Cable fly/
    delete exercise_path(own)
    assert_match "was not deleted", flash[:alert]
    delete workout_exercise_path(day.workout_exercises.find_by!(exercise: own))
    assert_redirected_to day
    delete exercise_path(own)
    assert_not Exercise.exists?(own.id)

    # an exercise an admin creates in the modal goes to the shared catalogue
    sign_out @user
    sign_in @admin
    admin_day = @admin.splits.create!(name: "Admin").workout_days.create!(day: "Legs", weekday: 2)
    post workout_day_workout_exercises_path(admin_day), params: { exercise: { name: "Leg curl", muscle_group: "Legs" } }
    assert Exercise.shared.exists?(name: "Leg curl")
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
    assert_select "table.set-table tbody tr", 2
    assert_select "input[name='workout_set[reps_completed]'][value='6']"
    assert_select "input[name='workout_set[weight_used]'][value='82.5']"

    delete workout_set_path(entry.workout_sets.find_by!(set_number: 2))
    assert_equal 1, entry.workout_sets.count
    post workout_exercise_workout_sets_path(planned), params: { workout_set: { reps_completed: 7 } }
    assert_equal [1, 2], entry.workout_sets.order(:set_number).pluck(:set_number)

    # equipment: free weights, or a machine with a typed brand
    patch workout_exercise_path(planned), params: { workout_exercise: { equipment: "machine", machine_brand: "" } }
    assert_match "Machine brand can't be blank", flash[:alert]
    patch workout_exercise_path(planned), params: { workout_exercise: { equipment: "machine", machine_brand: "Acme" } }
    assert_redirected_to workout_exercise_path(planned)
    assert_equal "Machine · Acme", planned.reload.equipment_label
    patch workout_exercise_path(planned), params: { workout_exercise: { equipment: "free_weights" } }
    assert_nil planned.reload.machine_brand

    get workout_day_path(day)
    assert_select ".chip", text: "2 sets today"

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
    post workout_log_workout_log_exercises_path(log), params: { exercise_ids: [@bench.id] }
    post workout_log_workout_log_exercises_path(log), params: { exercise: { name: "Dips", muscle_group: "Triceps" } }
    post workout_log_workout_log_exercises_path(log), params: { exercise_ids: [] }
    assert_match "Choose at least one exercise", flash[:alert]
    assert_equal ["Bench press", "Squat", "Bench press", "Dips"], log.workout_log_exercises.order(:id).pluck(:name)
    assert_equal "Dips", @user.exercises.sole.name

    # the equipment of a logged exercise can be changed without touching the day
    get edit_workout_log_exercise_path(entry)
    assert_response :success
    patch workout_log_exercise_path(entry), params: { workout_log_exercise: { equipment: "machine", machine_brand: "" } }
    assert_response :unprocessable_entity
    patch workout_log_exercise_path(entry), params: { workout_log_exercise: { equipment: "machine", machine_brand: "Beta" } }
    assert_equal "Machine · Beta", entry.reload.equipment_label
    assert_equal "free_weights", planned.reload.equipment

    get workout_log_path(log)
    assert_response :success
    assert_select "p", /Machine · Beta/

    delete workout_log_exercise_path(entry)
    assert_equal 3, log.workout_log_exercises.count
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
    post exercises_path, params: { exercise: { name: "" } }
    assert_response :unprocessable_entity
    post exercises_path, params: { exercise: { name: "Deadlift", muscle_group: "Back" } }
    deadlift = Exercise.find_by!(name: "Deadlift")
    assert deadlift.shared?
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

  test "signing up cannot grant admin" do
    post user_registration_path, params: { user: { email: "new@example.com", password: "secret123", password_confirmation: "secret123", admin: true } }
    assert_not User.find_by!(email: "new@example.com").admin?
  end
end
