require "test_helper"

# Back buttons and paged lists.
class NavigationFlowTest < FlowTest
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
    assert_response :unprocessable_content
    assert_select "a.back-link", text: "PPL"

    # only an admin reaches the catalogue form
    sign_in @admin
    get new_exercise_path
    assert_select "a.back-link[href=?]", exercises_path, text: "Exercises", count: 1
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
end
