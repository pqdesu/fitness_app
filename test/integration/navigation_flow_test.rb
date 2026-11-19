require "test_helper"

# Back buttons and paged lists.
class NavigationFlowTest < FlowTest
  test "every sub-page has one back arrow, falling back to its parent; top-level pages have none" do
    sign_in @user
    mine = Exercise.create!(name: "Cable fly", muscle_group: "Chest", user: @user)
    split = @user.splits.create!(name: "PPL")
    day = split.workout_days.create!(day: "Push", weekday: Date.current.wday)
    planned = day.workout_exercises.create!(exercise: @bench)
    post workout_exercise_workout_sets_path(planned), params: { workout_set: { reps_completed: 8, weight_used: 80 } }
    log = @user.workout_logs.sole
    # an exercise page and a logged workout go back to their day on their date
    entry = log.workout_log_exercises.sole

    {
      edit_exercise_path(mine) => exercises_path,
      new_split_path => splits_path,
      split_path(split) => splits_path,
      edit_split_path(split) => split_path(split),
      new_split_workout_day_path(split) => split_path(split),
      workout_day_path(day) => root_path,
      edit_workout_day_path(day) => split_path(split, anchor: "day-#{day.id}"),
      workout_exercise_path(planned) => workout_day_path(day, date: Date.current),
      workout_log_path(log) => workout_day_path(day, date: log.date),
      edit_workout_log_exercise_path(entry) => workout_log_path(log)
    }.each do |path, parent|
      get path
      assert_response :success, "#{path} failed"
      assert_select "a.back-link[aria-label=Back][data-controller=back][data-action='back#go']", { count: 1, text: "" }, "#{path} back arrow"
      assert_select "a.back-link[href=?]", parent, { count: 1 }, "#{path} back target"
    end

    # a form page is marked, so the arrow goes past it once the form is saved
    get edit_split_path(split)
    assert_select "body[data-back-skip=true]"
    get split_path(split)
    assert_select "body[data-back-skip=false]"

    [root_path, splits_path, workout_logs_path, exercises_path].each do |path|
      get path
      assert_select "a.back-link", false, "#{path} should have no back button"
    end

    # a rejected form keeps pointing at the saved name, not the one being typed
    patch split_path(split), params: { split: { name: "" } }
    assert_response :unprocessable_content
    assert_select "a.back-link[href=?]", split_path(split), count: 1

    # only an admin reaches the catalogue form
    sign_in @admin
    get new_exercise_path
    assert_select "a.back-link[href=?]", exercises_path, count: 1
  end

  test "on a phone the history puts date, workout, split and counts in one cell" do
    sign_in @user
    planned = @user.splits.create!(name: "PPL").workout_days.create!(day: "Push", weekday: 1)
                   .workout_exercises.create!(exercise: @bench, name: "Bench press")
    entry = planned.entry_on!(Date.new(2026, 11, 16))
    entry.workout_sets.create!(reps_completed: 8, weight_used: 60)
    entry.workout_sets.create!(reps_completed: 6, weight_used: 65)

    get workout_logs_path
    assert_select "td.history-summary.d-md-none" do
      assert_select "a", text: "November 16, 2026"
      assert_select ".history-line", text: /Push/
      assert_select ".history-line .chip", text: "PPL"
      assert_select ".history-counts", text: "1 exercise · 2 sets"
    end
    # the separate columns are only for wider screens
    assert_select "th.d-none.d-md-table-cell", 5
    assert_select "td.d-none.d-md-table-cell", 5
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

  test "a list sent where one value is expected is ignored, not an error page" do
    sign_in @admin
    split = @admin.splits.create!(name: "PPL")

    get "#{workout_logs_path}?page[]=1"
    assert_response :success
    get "#{exercises_path}?page[a]=1"
    assert_response :success
    get "#{admin_users_path}?page[]=2"
    assert_response :success
    get "#{workout_logs_path}?date[]=2026-11-17"
    assert_response :success
    get "#{new_split_workout_day_path(split)}?weekday[]=3"
    assert_response :success
  end

  test "a flash message is a card that leaves by itself and stays out of the page cache" do
    sign_in @user
    post splits_path, params: { split: { name: "PPL" } }
    follow_redirect!
    assert_select ".flash-stack[data-turbo-temporary] .flash.flash-notice[role=status][data-controller=flash]", 1
    assert_select ".flash-notice .flash-close[data-action='flash#dismiss']", 1

    get admin_users_path
    follow_redirect!
    assert_select ".flash.flash-alert[role=alert]", text: /Only an admin can do that/

    get root_path
    assert_select ".flash-stack", false
  end

  test "a delete asks in the app's own box, not the browser's" do
    sign_in @user
    log = @user.workout_logs.create!(workout: "Push", date: Date.current)
    get workout_log_path(log)
    assert_select "form[action=?][data-turbo-confirm='Delete this workout and all its sets?']", workout_log_path(log)
    assert_select "#confirm-modal.modal" do
      assert_select "[data-confirm-title]", 1
      assert_select "[data-confirm-detail]", 1
      assert_select "button[data-bs-dismiss=modal]", "Cancel"
      assert_select "button[data-confirm-accept]", 1
    end
  end
end

