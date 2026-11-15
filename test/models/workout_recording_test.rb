require "test_helper"

# Covers the chain used to record a workout:
# user -> split -> workout day -> workout exercise -> log -> log exercise -> sets
class WorkoutRecordingTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(email: "lifter@example.com", password: "secret123")
    @split = @user.splits.create!(name: "PPL")
    @day = @split.workout_days.create!(day: "Push", order_index: 1)
    @exercise = Exercise.create!(name: "Bench press")
    @workout_exercise = @day.workout_exercises.create!(exercise: @exercise, sets: 3, reps: 8, target_weight: 80)
    @log = @day.workout_logs.create!(date: Date.current)
    @log_exercise = @log.workout_log_exercises.create!(workout_exercise: @workout_exercise)
  end

  test "an exercise in use cannot be destroyed" do
    assert_not @exercise.destroy
    assert @exercise.errors[:base].any?
    assert Exercise.exists?(@exercise.id)
  end

  test "an unused exercise can be destroyed" do
    assert Exercise.create!(name: "Squat").destroy
  end

  test "exercise reaches its logged entries through workout exercises" do
    assert_equal [@log_exercise], @exercise.workout_log_exercises.to_a
  end

  test "planned sets and reps must be positive integers" do
    [{ sets: -1 }, { sets: 0 }, { reps: 0 }, { reps: 2.5 }, { target_weight: -5 }].each do |attrs|
      record = @day.workout_exercises.build({ exercise: @exercise, sets: 3, reps: 8 }.merge(attrs))
      assert_not record.valid?, "expected #{attrs} to be invalid"
    end
  end

  test "target weight is optional" do
    assert @day.workout_exercises.build(exercise: @exercise, sets: 3, reps: 8).valid?
  end

  test "recorded set numbers must be valid" do
    [{ set_number: 0 }, { reps_completed: -1 }, { reps_completed: 1.5 }, { weight_used: -1 }].each do |attrs|
      record = @log_exercise.workout_sets.build({ set_number: 1, reps_completed: 8, weight_used: 80 }.merge(attrs))
      assert_not record.valid?, "expected #{attrs} to be invalid"
    end
  end

  test "a set may record zero reps and no weight" do
    assert @log_exercise.workout_sets.build(set_number: 1, reps_completed: 0).valid?
  end

  test "set number is unique per logged exercise in rails and in the database" do
    @log_exercise.workout_sets.create!(set_number: 1, reps_completed: 8)
    duplicate = @log_exercise.workout_sets.build(set_number: 1, reps_completed: 6)

    assert_not duplicate.valid?
    assert_raises(ActiveRecord::RecordNotUnique) { duplicate.save!(validate: false) }
  end

  test "required columns are not null in the database" do
    assert_raises(ActiveRecord::NotNullViolation) do
      WorkoutLog.new(workout_day: @day).save!(validate: false)
    end
  end

  test "user reaches their own logs only" do
    other = User.create!(email: "other@example.com", password: "secret123")
    other_day = other.splits.create!(name: "Upper/Lower").workout_days.create!(day: "Upper", order_index: 1)
    other_log = other_day.workout_logs.create!(date: Date.current)

    assert_equal [@log], @user.workout_logs.to_a
    assert_equal [other_log], other.workout_logs.to_a
    assert_equal @user, @log.user
  end

  test "a log cannot record an exercise planned for a different day" do
    other_day = @split.workout_days.create!(day: "Pull", order_index: 2)
    other_exercise = other_day.workout_exercises.create!(exercise: @exercise, sets: 3, reps: 8)
    entry = @log.workout_log_exercises.build(workout_exercise: other_exercise)

    assert_not entry.valid?
    assert entry.errors[:workout_exercise].any?
  end
end
