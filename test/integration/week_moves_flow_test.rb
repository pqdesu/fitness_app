require "test_helper"

# Rest days and moving a workout for one week.
class WeekMovesFlowTest < FlowTest
  test "on a rest day a workout can be started anyway, and it is recorded as a rest day workout" do
    sign_in @user
    split = @user.splits.create!(name: "PPL")
    push = split.workout_days.create!(day: "Push", weekday: 1)
    planned = split.workout_days.create!(day: "Pull", weekday: 3)
    planned.workout_exercises.create!(exercise: @squat)

    # Tuesday: nothing planned
    travel_to Time.zone.local(2026, 11, 17, 12) do
      get root_path
      assert_select ".today-title", "Rest day"
      assert_select ".today-header button.btn-primary[data-bs-target='#rest-day-start']", "Start workout"
      # one pill per workout of the split, by name only; its pop-up trains it as an extra
      assert_equal %w[Push Pull], css_select("#rest-day-start.collapse:not(.show) button[data-bs-toggle='modal']").map(&:text)
      assert_select "#rest-start-0 a[href=?]", workout_day_path(push), text: "Train as extra"
      assert_select "#rest-day-start", /saved as a rest day workout/

      # the first set creates the log, marked as a rest day, and the split is untouched
      entry = planned.workout_exercises.first
      assert_difference -> { WorkoutLog.count }, 1 do
        post workout_exercise_workout_sets_path(entry), params: { workout_set: { reps_completed: 5, weight_used: 100 } }
      end
      log = WorkoutLog.order(:id).last
      assert log.rest_day?
      assert_equal 2, split.workout_days.reload.count

      get root_path
      assert_select ".today", /Logged today · Pull, 1 set/
      assert_select ".today .chip-rest", "Rest day"
      assert_select ".recent-row .chip-rest", "Rest day"
      get workout_log_path(log)
      assert_select ".page-header .chip-rest", "Rest day, trained anyway"
      get workout_logs_path
      assert_select "td .chip-rest", "Rest day"
    end

    # a planned day is not a rest day
    travel_to Time.zone.local(2026, 11, 16, 12) do
      assert_not push.workout_logs.create!(date: Date.current).rest_day?
    end
  end

  test "a workout is moved to another day for this week only, and the split keeps its plan" do
    sign_in @user
    split = @user.splits.create!(name: "Upper Lower")
    upper = split.workout_days.create!(day: "Upper", weekday: 1)
    lower = split.workout_days.create!(day: "Lower", weekday: 3)
    lower.workout_exercises.create!(exercise: @squat)

    # Tuesday 2026-11-17: a rest day in the plan
    travel_to Time.zone.local(2026, 11, 17, 12) do
      get root_path
      assert_select ".today-title", "Rest day"
      assert_select ".week-moves button[data-bs-target='#move-workout']", /Move a workout/
      assert_select ".week-moves", { text: /Back to the plan/, count: 0 }
      # the pop-up offers the workouts of the week, and only today and the days after it
      assert_select "#move-workout input[name='workout_day_id']", 2
      assert_equal %w[2 3 4 5 6], css_select("#move-workout input[name='weekday']").map { |input| input["value"] }
      assert_select "#move-workout label[for='move_to_2']", /Today\s+Free/
      assert_select "#move-workout label[for='move_to_3']", /Wed\s+Lower/
      # on a rest day a workout of the split is one pill, with "Move to today" in its pop-up
      assert_select "#rest-start-1 .modal-title", "Lower today"
      assert_select "#rest-start-1", /Lower is planned on Wednesday/
      assert_select "#rest-start-1 form[action=?]", split_week_move_path(split), text: "Move to today"

      # a day that is past cannot be chosen
      post split_week_move_path(split), params: { workout_day_id: lower.id, weekday: 1 }
      assert_redirected_to root_path
      assert_match(/Not moved: choose a day from today to Saturday/, flash[:alert])
      assert_equal 0, WorkoutDayMove.count

      # "Move to today" moves it and opens the workout day
      post split_week_move_path(split), params: { workout_day_id: lower.id, weekday: 2, open: 1 }
      assert_redirected_to workout_day_path(lower)
      assert_match(/Lower is on Tuesday this week/, flash[:notice])
      assert_equal [3, 1], [lower.reload.weekday, upper.reload.weekday], "the split keeps its plan"

      get root_path
      assert_select ".today-title", "Lower day"
      assert_select ".today-moved", "Moved from Wednesday, this week only"
      assert_select ".week .week-day.is-today.is-set.is-moved[href=?]", workout_day_path(lower)
      assert_select ".week a.week-day:not(.is-set)[aria-label=?][href=?]", "Wednesday: no workout this week, it was moved", split_path(split)
      assert_select ".week-moves", /Moved this week/
      # the split's own page still shows the plan
      get split_path(split)
      assert_select ".week .week-day.is-moved", 0
      assert_select ".week .week-day.is-set", 2

      # trained on its moved day it is a planned workout, not a rest day one
      post workout_exercise_workout_sets_path(lower.workout_exercises.first), params: { workout_set: { reps_completed: 5, weight_used: 100 } }
      log = WorkoutLog.order(:id).last
      assert_not log.rest_day?
      # and once trained it is not offered to be moved again
      get root_path
      assert_select "#move-workout input[name='workout_day_id']", 1
      post split_week_move_path(split), params: { workout_day_id: lower.id, weekday: 4 }
      assert_match(/Lower is already logged this week/, flash[:alert])
    end

    # Wednesday of that week is a rest day; the week after is back to the plan
    travel_to(Time.zone.local(2026, 11, 18, 12)) { get root_path and assert_select ".today-title", "Rest day" }
    travel_to(Time.zone.local(2026, 11, 25, 12)) do
      get root_path
      assert_select ".today-title", "Lower day"
      assert_select ".week .week-day.is-moved", 0
    end
  end

  test "moving a workout onto a day that has one swaps the two, and the week can go back to the plan" do
    sign_in @user
    split = @user.splits.create!(name: "Upper Lower")
    upper = split.workout_days.create!(day: "Upper", weekday: 1)
    lower = split.workout_days.create!(day: "Lower", weekday: 3)

    # Monday 2026-11-16
    travel_to Time.zone.local(2026, 11, 16, 12) do
      post split_week_move_path(split), params: { workout_day_id: lower.id, weekday: 1 }
      assert_redirected_to root_path
      assert_match(/Lower is on Monday this week, and Upper on Wednesday/, flash[:notice])
      assert_equal({ 1 => lower, 3 => upper }, split.week_plan(Date.current))
      get root_path
      assert_select ".today-title", "Lower day"
      assert_select "#move-workout .picker-row", /Upper\s+Wednesday, planned Monday/

      # moving it back to its own day removes the move, for both
      post split_week_move_path(split), params: { workout_day_id: lower.id, weekday: 3 }
      assert_equal 0, WorkoutDayMove.count

      post split_week_move_path(split), params: { workout_day_id: upper.id, weekday: 5 }
      assert_equal({ 3 => lower, 5 => upper }, split.week_plan(Date.current))
      delete split_week_move_path(split)
      assert_redirected_to root_path
      assert_equal({ 1 => upper, 3 => lower }, split.week_plan(Date.current))

      # changing the plan's weekdays starts the weeks from the plan again
      post split_week_move_path(split), params: { workout_day_id: upper.id, weekday: 5 }
      split.workout_days.create!(day: "Push", weekday: 5)
      assert_equal 0, WorkoutDayMove.count
    end

    # another user's split cannot be moved
    sign_in @admin
    post split_week_move_path(split), params: { workout_day_id: lower.id, weekday: 6 }
    assert_response :not_found
  end

  test "on a rest day a workout outside the split is started by picking its exercises" do
    sign_in @user
    split = @user.splits.create!(name: "Legs only")
    split.workout_days.create!(day: "Legs", weekday: 1)

    travel_to Time.zone.local(2026, 11, 17, 12) do
      get root_path
      # every fixed workout the split does not have; Lower is the same workout as Legs
      assert_equal WorkoutDay::NAMES - %w[Legs Lower], css_select("#rest-day-start a[href*='workout_logs/new']").map(&:text)

      # opening it saves nothing
      assert_no_difference -> { WorkoutLog.count } do
        get new_workout_log_path(workout: "Push")
        assert_response :success
      end
      assert_select "h1", "Push workout"
      assert_select ".back-link[href=?]", root_path
      assert_select "#exercise-picker form[action=?]", workout_logs_path(workout: "Push")
      post workout_logs_path(workout: "Push")
      assert_redirected_to new_workout_log_path(workout: "Push")
      assert_equal 0, WorkoutLog.count

      # the first exercise creates today's workout, as a rest day workout with no split day
      post workout_logs_path(workout: "Push"), params: { exercise_ids: [@bench.id] }
      log = WorkoutLog.order(:id).last
      assert_redirected_to workout_log_path(log, from: "dashboard")
      assert_equal ["Push", Date.new(2026, 11, 17), nil, true, @user], [log.workout, log.date, log.workout_day, log.rest_day?, log.user]
      assert_equal ["Bench press"], log.workout_log_exercises.pluck(:name)
      assert_equal 1, split.workout_days.count

      # sets are added on the workout's page, and starting Push again opens the same workout
      post workout_log_exercise_workout_sets_path(log.workout_log_exercises.first), params: { workout_set: { reps_completed: 8, weight_used: 60 } }
      get new_workout_log_path(workout: "Push")
      assert_redirected_to workout_log_path(log, from: "dashboard")
      get root_path
      assert_select ".today", /Logged today · Push, 1 set/
      assert_select ".today .chip-rest", "Rest day"

      # only the fixed workouts
      get new_workout_log_path(workout: "Chest day")
      assert_redirected_to root_path
    end
  end
end
