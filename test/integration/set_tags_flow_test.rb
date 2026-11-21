require "test_helper"

# Tags on sets (warm-up, assisted…), which only an admin manages, and the note of an exercise for the day.
class SetTagsFlowTest < FlowTest
  setup do
    @warm_up = SetTag.create!(name: "Warm-up")
    @assisted = SetTag.create!(name: "Assisted")
    @day = @user.splits.create!(name: "PPL").workout_days.create!(day: "Push", weekday: Date.current.wday)
    @planned = @day.workout_exercises.create!(exercise: @bench)
    @page = workout_exercise_path(@planned, date: Date.current)
  end

  test "only an admin manages the set tags" do
    sign_in @user
    get admin_set_tags_path
    assert_redirected_to root_path
    post admin_set_tags_path, params: { set_tag: { name: "Drop set" } }
    assert_nil SetTag.find_by(name: "Drop set")

    sign_in @admin
    get edit_user_registration_path
    assert_select "a[href=?]", admin_set_tags_path, text: /Set tags/
    get admin_set_tags_path
    assert_equal %w[Assisted Warm-up], css_select("#set-tags .row-title").map(&:text)
    post admin_set_tags_path, params: { set_tag: { name: " Drop  set " } }
    assert_equal "Drop set", SetTag.order(:id).last.name
    post admin_set_tags_path, params: { set_tag: { name: "warm-up" } }
    assert_response :unprocessable_content
    patch admin_set_tag_path(@assisted), params: { set_tag: { name: "Spotted" } }
    assert_equal "Spotted", @assisted.reload.name
  end

  test "a set is tagged when it is added or edited, and a deleted tag comes off it" do
    sign_in @user
    get @page
    # one pill per tag under "Add set", none ticked
    assert_select ".set-form .set-tag-choices input[type=checkbox][name='workout_set[set_tag_ids][]']:not([checked])", 2
    assert_equal %w[Assisted Warm-up], css_select(".set-form .set-tag-choices label").map(&:text)
    radio_ids = css_select(".set-form .set-tag-choices input").map { |input| input["id"] }
    assert_equal radio_ids, css_select(".set-form .set-tag-choices label").map { |label| label["for"] }

    post workout_exercise_workout_sets_path(@planned, date: Date.current),
         params: { workout_set: { reps_completed: 10, weight_used: 40, set_tag_ids: [@warm_up.id] } }
    post workout_exercise_workout_sets_path(@planned, date: Date.current), params: { workout_set: { reps_completed: 5, weight_used: 80 } }
    first, second = @user.workout_sets.order(:set_number).to_a
    assert_equal [["Warm-up"], []], [first.set_tags.map(&:name), second.set_tags.map(&:name)]

    get @page
    assert_select "tbody:first-of-type .set-tags .chip-tag", "Warm-up"
    # a Tag button of its own, outside the ⋯ menu, opens the tags; ticking one saves the set at once
    assert_select "tbody:first-of-type .set-tags button.set-tag-toggle[data-bs-target='#set-#{first.id}-tags']", text: /Tag/
    assert_select ".actions-menu .set-tag-choices", 0
    assert_select "tr[data-row-edit-target=field] .set-tag-choices", 0
    assert_select "#set-#{first.id}-tags.collapse:not(.show) input[data-action='change->row-edit#save']", 2
    assert_select "input#tag_set_#{first.id}_#{@warm_up.id}[form='edit_set_#{first.id}'][checked]", 1
    assert_select "input[type=hidden][name='workout_set[set_tag_ids][]'][value=''][form='edit_set_#{first.id}']", 1
    patch workout_set_path(second, workout_exercise_id: @planned.id, date: Date.current),
          params: { workout_set: { reps_completed: 5, weight_used: 80, set_tag_ids: ["", @assisted.id, @warm_up.id] } }
    assert_equal %w[Assisted Warm-up], second.reload.set_tags.map(&:name)
    patch workout_set_path(first, workout_exercise_id: @planned.id, date: Date.current),
          params: { workout_set: { reps_completed: 10, weight_used: 40, set_tag_ids: [""] } }
    assert_empty first.reload.set_tags

    # the logged workout page shows them too
    get workout_log_path(first.workout_log_exercise.workout_log_id)
    assert_select ".set-tags .chip-tag", %w[Assisted Warm-up].size

    # an admin deleting a tag takes it off the sets
    sign_in @admin
    delete admin_set_tag_path(@warm_up)
    assert_equal ["Assisted"], second.reload.set_tags.map(&:name)
  end

  test "with the account's warm-up setting, an exercise's first set of the day starts tagged Warm-up" do
    sign_in @user
    get edit_user_registration_path
    assert_select "input[type=checkbox][name='user[auto_warm_up]']", 1
    patch user_registration_path, params: { user: { auto_warm_up: "1", current_password: "secret123" } }
    assert @user.reload.auto_warm_up?

    get @page
    assert_select ".set-form input#tag_workout_exercise_#{@planned.id}_#{@warm_up.id}[checked]", 1
    assert_select ".set-form input#tag_workout_exercise_#{@planned.id}_#{@assisted.id}:not([checked])", 1
    post workout_exercise_workout_sets_path(@planned, date: Date.current),
         params: { workout_set: { reps_completed: 10, weight_used: 40, set_tag_ids: [@warm_up.id] } }
    # the next set is not a warm-up unless ticked
    get @page
    assert_select ".set-form input#tag_workout_exercise_#{@planned.id}_#{@warm_up.id}:not([checked])", 1
    # off, nothing starts ticked
    @user.update!(auto_warm_up: false)
    other = @day.workout_exercises.create!(exercise: @squat)
    get workout_exercise_path(other, date: Date.current)
    assert_select ".set-form .set-tag-choices input[checked]", 0
  end

  test "an exercise has a note for the day once it is being logged" do
    sign_in @user
    # nothing is logged yet: no note to write, and opening the page logs nothing
    get @page
    assert_select ".exercise-note", 0
    assert_equal 0, @user.workout_logs.count

    post workout_exercise_workout_sets_path(@planned, date: Date.current), params: { workout_set: { reps_completed: 8, weight_used: 60 } }
    entry = @planned.entry_on(Date.current)
    note_path = workout_log_exercise_path(entry, workout_exercise_id: @planned.id, date: Date.current)
    get @page
    assert_select ".exercise-note form[action=?] textarea[name='workout_log_exercise[notes]']", note_path

    patch note_path, params: { workout_log_exercise: { notes: "  Seat on 4  " } }
    assert_redirected_to @page
    assert_equal ["Seat on 4", "Free weights"], entry.reload.then { |e| [e.notes, e.equipment_label] }
    follow_redirect!
    assert_select ".exercise-note textarea", "Seat on 4"
    # it is the logged exercise's note: the logged workout shows it
    get workout_log_path(entry.workout_log_id)
    assert_select "#entry-#{entry.id} .entry-note", /Seat on 4/

    patch note_path, params: { workout_log_exercise: { notes: "x" * 501 } }
    assert_redirected_to @page
    assert_match "Note not saved", flash[:alert]
    assert_equal "Seat on 4", entry.reload.notes
  end
end
