require "test_helper"

# The note of an exercise for the day.
class SetTagsFlowTest < FlowTest
  setup do
    @day = @user.splits.create!(name: "PPL").workout_days.create!(day: "Push", weekday: Date.current.wday)
    @planned = @day.workout_exercises.create!(exercise: @bench)
    @page = workout_exercise_path(@planned, date: Date.current)
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
