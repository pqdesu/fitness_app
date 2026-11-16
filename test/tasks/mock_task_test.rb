require "test_helper"
require "rake"

# bin/rails mock:last_week and mock:clear (lib/tasks/mock.rake)
class MockTaskTest < ActiveSupport::TestCase
  setup do
    Rails.application.load_tasks unless Rake::Task.task_defined?("mock:last_week")
    @user = User.create!(email: "lifter@example.com", password: "secret123")
    @bench = Exercise.create!(name: "Bench press", muscle_group: "Chest")
    ppl = @user.splits.create!(name: "PPL")
    # Push has its own plan; Legs is empty and gets one from the task
    @push = ppl.workout_days.create!(day: "Push", weekday: 1)
    @planned = @push.workout_exercises.create!(exercise: @bench)
    @legs = ppl.workout_days.create!(day: "Legs", weekday: 3)
    # another split with the same workout on the same weekday: one session per workout per day
    @other_push = @user.splits.create!(name: "Other").workout_days.create!(day: "Push", weekday: 1)
  end

  test "last_week logs each workout of last week once, and clear removes what it added" do
    travel_to Time.zone.local(2026, 11, 18, 12) do # Wednesday; last week is November 8 to 14
      output = run_task("mock:last_week")
      assert_match(/logged .*PPL · Push on Mon Nov 9/, output)
      assert_match(/logged .*PPL · Legs on Wed Nov 11/, output)
      assert_match(/skipped .*Other · Push on Mon Nov 9/, output)

      logs = @user.workout_logs.order(:date)
      assert_equal [[Date.new(2026, 11, 9), "Push"], [Date.new(2026, 11, 11), "Legs"]], logs.pluck(:date, :workout)
      push_entry = logs.first.workout_log_exercises.sole
      assert_equal [@planned, 3], [push_entry.workout_exercise, push_entry.workout_sets.count]
      assert_equal [[80, 8], [80, 7], [80, 6]], push_entry.workout_sets.order(:set_number).pluck(:weight_used, :reps_completed)
      # the empty day received a plan, and every exercise of it was logged
      assert_equal ["Squat", "Romanian deadlift", "Leg press", "Calf raise"], @legs.workout_exercises.order(:id).pluck(:name)
      assert_equal 4, logs.last.workout_log_exercises.count
      assert_empty @other_push.workout_exercises

      # running it again adds nothing
      assert_no_difference ["WorkoutLog.count", "WorkoutSet.count", "WorkoutExercise.count"] do
        assert_match(/skipped .*PPL · Push/, run_task("mock:last_week"))
      end

      # a real workout, and real sets on one of the exercises the task planned
      real = @push.workout_logs.create!(date: Date.new(2026, 11, 16))
      real.workout_log_exercises.create!(workout_exercise: @planned).workout_sets.create!(reps_completed: 8, weight_used: 82.5)
      squat = @legs.workout_exercises.find_by!(name: "Squat")
      squat.entry_on!(Date.current).workout_sets.create!(reps_completed: 5, weight_used: 100)

      output = run_task("mock:clear")
      assert_match "lifter@example.com: 2 mock workouts and 3 planned exercises deleted", output
      # only the real workouts are left; the user's own plan is untouched, and of the plan the
      # task added only the exercise used since stays
      assert_equal [Date.new(2026, 11, 16), Date.current], @user.workout_logs.order(:date).pluck(:date)
      assert_equal [@planned], @push.workout_exercises.to_a
      assert_equal [squat], @legs.workout_exercises.to_a
      assert Exercise.shared.exists?(name: "Leg press")
    end
  end

  private

  def run_task(name)
    task = Rake::Task[name]
    task.reenable
    capture_io { task.invoke }.first
  end
end
