require "test_helper"

# The design audit's polish pass: the calendar key, Delete at the bottom, the folded equipment,
# the admin pages in the top bar, page titles, button labels and placeholders.
class DesignPolishFlowTest < FlowTest
  setup do
    @split = @user.splits.create!(name: "PPL")
    @day = @split.workout_days.create!(day: "Push", weekday: 1)
    @planned = @day.workout_exercises.create!(exercise: @bench, name: "Bench press")
  end

  test "the calendar has a key of four marks under the grid, which are not days" do
    sign_in @user
    get root_path
    assert_select "#calendar-body .calendar-legend li", 4
    assert_equal %w[Planned Missed Extra Today], css_select(".calendar-legend li").map { |n| n.text.squish }
    assert_select ".calendar-legend .calendar-day", 0
  end

  test "Delete workout is the last thing on a logged workout, not in its header" do
    sign_in @user
    log = @day.workout_logs.create!(date: Date.current)
    log.workout_log_exercises.create!(name: "Bench press")
    get workout_log_path(log)
    assert_select ".page-header form", 0
    assert_select "form.delete-workout[data-turbo-confirm] button.btn-link.text-danger", "Delete workout"
  end

  test "the equipment of an exercise is one row that opens its form" do
    sign_in @user
    get workout_exercise_path(@planned, date: Date.current)
    assert_select "button.choice-summary[data-bs-target='#equipment-form'][aria-expanded=false]", /Equipment\s+#{@planned.equipment_label}/
    assert_select "#equipment-form.collapse:not(.show) form input[type=submit][value='Save equipment']", 1
  end

  test "the admin's equipment and set tags pages are named in the top bar, go back to Account and light its tab" do
    sign_in @admin
    [[admin_equipment_items_path, "Equipment"], [admin_set_tags_path, "Set tags"]].each do |path, title|
      get path
      assert_select ".navbar-page-title", title
      assert_select "a.back-link[href=?]", edit_user_registration_path
      assert_select ".bottom-nav-item.active", /Account/
      assert_select "title", "#{title} · FitnessApp"
    end
    get admin_users_path
    assert_select ".bottom-nav-item.active", /Account/
    assert_select "a.back-link", 0
  end

  test "the page title names the page, an exercise or a workout by its own name" do
    sign_in @user
    get root_path
    assert_select "title", "Home · FitnessApp"
    get workout_exercise_path(@planned, date: Date.current)
    assert_select "title", "Bench press · FitnessApp"
    get workout_day_path(@day, date: Date.new(2026, 11, 16))
    assert_select "title", /\APush · \w{3} 16 Nov( 2026)? · FitnessApp\z/
    sign_out @user
    get new_user_session_path
    assert_select "title", "FitnessApp"
  end

  test "a workout day's counts are said once, in the card header" do
    sign_in @user
    entry = @planned.entry_on!(Date.current)
    entry.workout_sets.create!(reps_completed: 8, weight_used: 60)
    get workout_day_path(@day, date: Date.current)
    assert_select ".page-header .day-counts", 0
    assert_select ".card-header .day-counts", "· 1 exercise · 1 set"
  end

  test "the exercise page names the day once: Today alone, another day with its date" do
    sign_in @user
    get workout_exercise_path(@planned, date: Date.current)
    assert_select ".card-header h2", "Today"
    assert_select ".card-header .text-muted", 0
    assert_select ".exercise-note .card-header .text-muted", 0
    yesterday = Date.current - 1
    get workout_exercise_path(@planned, date: yesterday)
    assert_select ".card-header h2", yesterday.strftime("%A")
    assert_select ".card-header .text-muted", ApplicationController.helpers.short_date(yesterday)
  end

  test "buttons say what they do and the add-set form gives its fields hints" do
    sign_in @user
    get new_split_path
    assert_select "input[type=submit][value=?]", "Create split"
    assert_select "input[placeholder='e.g. Push / Pull / Legs']"
    get edit_split_path(@split)
    assert_select "input[type=submit][value=?]", "Save split"
    get new_split_workout_day_path(@split)
    assert_select "input[type=submit][value=?]", "Add workout day"
    sign_in @admin
    get new_exercise_path
    assert_select "input[type=submit][value=?]", "Create exercise"
    get edit_exercise_path(@bench)
    assert_select "input[type=submit][value=?]", "Save exercise"
    sign_in @user
    get workout_exercise_path(@planned, date: Date.current)
    assert_select "form.set-form button[data-turbo-submits-with='Adding…']", /Add set/
    assert_select "form.set-form input[placeholder=kg]", 1
    assert_select "form.set-form input[placeholder=reps]", 1
  end

  test "a logged workout's meta line keeps each part whole with its separator" do
    sign_in @user
    log = @day.workout_logs.create!(date: Date.current)
    entry = log.workout_log_exercises.create!(name: "Bench press", equipment: "free_weights")
    entry.workout_sets.create!(reps_completed: 8, weight_used: 60)
    get workout_log_path(log)
    parts = css_select("#entry-#{entry.id} .time-part").map { |n| n.text.squish }
    assert_equal 2, parts.size
    assert parts.first.end_with?("·")
    assert_not parts.last.end_with?("·")
  end

  test "an exercise name that is taken says it is already in the user's exercises" do
    @user.exercises.create!(name: "Pec deck")
    duplicate = @user.exercises.build(name: "pec deck")
    assert_not duplicate.valid?
    assert_equal ["Name is already in your exercises"], duplicate.errors.full_messages
  end

  test "an error names a field once, by its plain label" do
    sign_in @user
    post workout_exercise_workout_sets_path(@planned, date: Date.current), params: { workout_set: { reps_completed: "", weight_used: 80 } }
    assert_equal "Set not added: Reps can't be blank.", flash[:alert]
  end
end
