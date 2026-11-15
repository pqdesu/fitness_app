require "test_helper"

class WorkoutFlowTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @admin = User.create!(email: "admin@example.com", password: "secret123", admin: true)
    @user = User.create!(email: "lifter@example.com", password: "secret123")
    @bench = Exercise.create!(name: "Bench press", muscle_group: "Chest", equipment: "Barbell")
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

  test "planning a split and recording a workout" do
    sign_in @user

    get root_path
    assert_response :success
    get new_split_path
    assert_response :success

    post splits_path, params: { split: { name: "" } }
    assert_response :unprocessable_entity

    post splits_path, params: { split: { name: "PPL" } }
    split = @user.splits.last
    assert_redirected_to split
    follow_redirect!
    assert_response :success

    get new_split_workout_day_path(split)
    assert_response :success
    post split_workout_days_path(split), params: { workout_day: { day: "Push", order_index: 1 } }
    day = split.workout_days.last
    assert_redirected_to day
    follow_redirect!
    assert_response :success

    # invalid plan is rejected with a message, valid one is saved
    post workout_day_workout_exercises_path(day), params: { workout_exercise: { exercise_id: @bench.id, sets: -1, reps: 0 } }
    assert_redirected_to day
    assert_match "Sets must be greater than 0", flash[:alert]
    assert_equal 0, day.workout_exercises.count

    post workout_day_workout_exercises_path(day), params: { workout_exercise: { exercise_id: @bench.id, sets: 3, reps: 8, target_weight: 80 } }
    planned = day.workout_exercises.last
    assert_equal 80, planned.target_weight

    get edit_workout_exercise_path(planned)
    assert_response :success
    patch workout_exercise_path(planned), params: { workout_exercise: { reps: 10 } }
    assert_equal 10, planned.reload.reps
    get edit_workout_day_path(day)
    assert_response :success
    get edit_split_path(split)
    assert_response :success

    # start a workout: one log with an entry per planned exercise
    post workout_day_workout_logs_path(day)
    log = @user.workout_logs.last
    assert_redirected_to workout_log_path(log)
    assert_equal [planned], log.workout_exercises.to_a
    entry = log.workout_log_exercises.first
    follow_redirect!
    assert_response :success

    post workout_log_exercise_workout_sets_path(entry), params: { workout_set: { set_number: 1, reps_completed: 8, weight_used: 80 } }
    assert_equal 1, entry.workout_sets.count

    post workout_log_exercise_workout_sets_path(entry), params: { workout_set: { set_number: 1, reps_completed: 8, weight_used: 80 } }
    assert_match "Set number has already been taken", flash[:alert]
    assert_equal 1, entry.workout_sets.count

    patch workout_log_path(log), params: { workout_log: { notes: "Felt strong" } }
    assert_equal "Felt strong", log.reload.notes

    [workout_log_path(log), workout_logs_path, workout_day_path(day), split_path(split), splits_path, root_path].each do |path|
      get path
      assert_response :success, "#{path} failed"
    end

    # removing and re-adding a logged exercise
    delete workout_log_exercise_path(entry)
    assert_equal 0, log.workout_log_exercises.count
    get workout_log_path(log)
    assert_select "h2", "Planned but not in this workout"
    post workout_log_workout_log_exercises_path(log), params: { workout_exercise_id: planned.id }
    assert_equal 1, log.workout_log_exercises.count

    entry = log.workout_log_exercises.first
    post workout_log_exercise_workout_sets_path(entry), params: { workout_set: { set_number: 1, reps_completed: 8 } }
    delete workout_set_path(entry.workout_sets.first)
    assert_equal 0, entry.workout_sets.count

    delete workout_log_path(log)
    assert_redirected_to workout_logs_path
    delete workout_exercise_path(planned)
    delete workout_day_path(day)
    assert_redirected_to split
    delete split_path(split)
    assert_equal 0, @user.splits.count
  end

  test "users cannot reach another user's records" do
    split = @admin.splits.create!(name: "Private")
    day = split.workout_days.create!(day: "Legs", order_index: 1)
    planned = day.workout_exercises.create!(exercise: @bench, sets: 3, reps: 8)
    log = day.workout_logs.create!(date: Date.current)
    entry = log.workout_log_exercises.create!(workout_exercise: planned)

    [split_path(split), workout_day_path(day), edit_workout_exercise_path(planned), workout_log_path(log)].each do |path|
      sign_in @user # a 404 does not persist the test session, so sign in before each request
      get path
      assert_response :not_found, "#{path} was reachable"
    end
    sign_in @user
    post workout_log_exercise_workout_sets_path(entry), params: { workout_set: { set_number: 1, reps_completed: 8 } }
    assert_response :not_found
    sign_in @user
    post workout_day_workout_logs_path(day)
    assert_response :not_found
    assert_equal 0, entry.workout_sets.count
  end

  test "only admins manage the exercise catalogue" do
    sign_in @user
    get exercises_path
    assert_response :success
    get new_exercise_path
    assert_redirected_to exercises_path
    post exercises_path, params: { exercise: { name: "Squat" } }
    assert_nil Exercise.find_by(name: "Squat")
    delete exercise_path(@bench)
    assert Exercise.exists?(@bench.id)

    sign_out @user
    sign_in @admin
    get new_exercise_path
    assert_response :success
    post exercises_path, params: { exercise: { name: "" } }
    assert_response :unprocessable_entity
    post exercises_path, params: { exercise: { name: "Squat", muscle_group: "Legs" } }
    squat = Exercise.find_by!(name: "Squat")
    get edit_exercise_path(squat)
    assert_response :success
    patch exercise_path(squat), params: { exercise: { equipment: "Barbell" } }
    assert_equal "Barbell", squat.reload.equipment

    # an exercise that is in a plan is kept, with an explanation
    day = @admin.splits.create!(name: "PPL").workout_days.create!(day: "Legs", order_index: 1)
    day.workout_exercises.create!(exercise: squat, sets: 5, reps: 5)
    delete exercise_path(squat)
    assert Exercise.exists?(squat.id)
    assert_match "was not deleted", flash[:alert]

    delete exercise_path(@bench)
    assert_not Exercise.exists?(@bench.id)
  end

  test "signing up cannot grant admin" do
    post user_registration_path, params: { user: { email: "new@example.com", password: "secret123", password_confirmation: "secret123", admin: true } }
    assert_not User.find_by!(email: "new@example.com").admin?
  end
end
