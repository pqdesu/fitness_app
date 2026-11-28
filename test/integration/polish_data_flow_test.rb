require "test_helper"

# Empty workouts in the lists, the last-time line, and the installable app (manifest, layout tags).
class PolishDataFlowTest < FlowTest
  setup do
    @split = @user.splits.create!(name: "PPL")
    @day = @split.workout_days.create!(day: "Push", weekday: Date.current.wday)
    @planned = @day.workout_exercises.create!(exercise: @bench)
  end

  test "History and Recent say Timer only or Nothing logged, not zero counts" do
    sign_in @user
    WorkoutLog.create!(user: @user, workout_day: @day, date: Date.current - 14, started_at: Time.current)
    WorkoutLog.create!(user: @user, workout_day: @day, date: Date.current - 7).workout_log_exercises.create!(exercise: @bench)
    get workout_logs_path
    assert_select ".history-counts", text: "Timer only"
    assert_response :success
    assert_no_match(/0 exercises/, response.body)

    # an emptied one has no exercises at all
    WorkoutLog.where(date: Date.current - 7).first.workout_log_exercises.destroy_all
    get workout_logs_path
    assert_select ".history-counts", text: "Nothing logged"

    get root_path
    assert_select ".recent-summary", text: /Timer only|Nothing logged/
    assert_no_match(/0 exercises|0 sets/, response.body.scan(/class="recent-summary".*?<\/span>\s*<\/span>/m).join)
  end

  test "the exercise page says what was done last time, not on cardio or when there is none" do
    sign_in @user
    get workout_exercise_path(@planned)
    assert_select ".last-time", false

    entry = @planned.entry_on!(Date.current - 7)
    8.times { |i| entry.workout_sets.create!(reps_completed: 8 + i, weight_used: 100 + i) }
    get workout_exercise_path(@planned)
    assert_select ".last-time", text: /Last time · #{Regexp.escape(ApplicationController.helpers.short_date(Date.current - 7))}: 100×8 · 101×9 · 102×10 · 103×11 · 104×12 · 105×13 · …/

    cardio = Exercise.create!(name: "Treadmill", muscle_group: "Cardio")
    run = @day.workout_exercises.create!(exercise: cardio)
    get workout_exercise_path(run)
    assert_select ".last-time", false
  end

  test "the manifest is JSON and the layout points at it and the icons" do
    get pwa_manifest_path
    assert_response :success
    assert_equal "application/json", response.media_type
    json = JSON.parse(response.body)
    assert_equal ["FitnessApp", "standalone"], json.values_at("name", "display")
    assert_equal %w[192x192 512x512 512x512], json["icons"].pluck("sizes")
    json["icons"].each { |icon| assert File.exist?(Rails.root.join("public", icon["src"].delete_prefix("/"))) }

    get new_user_session_path
    assert_select "link[rel=manifest][href=?]", pwa_manifest_path
    assert_select "meta[name=theme-color][content='#FFFFFF']"
    assert_select "link[rel=apple-touch-icon][href=?]", "/icon-180.png"
    assert_select "link[rel=icon][href=?]", "/icon.svg"
  end
end
