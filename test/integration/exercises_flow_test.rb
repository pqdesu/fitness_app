require "test_helper"

# The exercise catalogue and a user's own exercises.
class ExercisesFlowTest < FlowTest
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
    assert_response :unprocessable_content
    # the form offers the shared catalogue, ticked; unticked the exercise is the admin's own
    assert_select "input[type=checkbox][name='exercise[shared]'][checked]", 1
    post exercises_path, params: { exercise: { name: "Deadlift", muscle_group: "Back", shared: "1" } }
    deadlift = Exercise.find_by!(name: "Deadlift")
    assert deadlift.shared?
    assert_match "added to the catalogue", flash[:notice]
    post exercises_path, params: { exercise: { name: "Deadlift", muscle_group: "Back", shared: "1" } }
    assert_response :unprocessable_content
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
    assert_select ".back-link[href=?]", workout_day_path(day), count: 1
    assert_select "input[type=hidden][name=workout_day_id][value=?]", day.id.to_s
    assert_select ".form-actions a[href=?]", workout_day_path(day), text: "Cancel"
    patch exercise_path(@bench), params: { exercise: { name: "" }, workout_day_id: day.id }
    assert_response :unprocessable_content
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

  test "the muscle group is chosen from the list, not typed" do
    sign_in @admin
    get edit_exercise_path(@bench)
    # Pills to tap, not a <select>, whose list can open past the bottom of a phone's screen
    assert_equal ["Other", *Exercise::MUSCLE_GROUPS], css_select(".choices label").map(&:text)
    assert_select "input[type=radio][name='exercise[muscle_group]'][checked][value=Chest]"
    assert_select "input[type=text][name='exercise[muscle_group]']", 0
    assert_select "select", 0

    patch exercise_path(@bench), params: { exercise: { name: "Bench press", muscle_group: "Pecs" } }
    assert_response :unprocessable_content
    assert_equal "Chest", @bench.reload.muscle_group

    # empty is allowed: the exercise is listed under "Other"
    patch exercise_path(@bench), params: { exercise: { name: "Bench press", muscle_group: "" } }
    assert_redirected_to exercises_path
    assert_nil @bench.reload.muscle_group
    assert_equal "Other", @bench.group
  end
end
