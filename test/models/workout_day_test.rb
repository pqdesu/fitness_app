require "test_helper"

class WorkoutDayTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(email: "lifter@example.com", password: "secret123")
    @split = @user.splits.create!(name: "PPL")
  end

  test "a workout day is one of the listed workouts" do
    WorkoutDay::NAMES.each_with_index do |name, weekday|
      assert @split.workout_days.build(day: name, weekday: weekday % 7).valid?, "#{name} should be allowed"
    end
    ["", "Chest day", "push"].each do |name|
      day = @split.workout_days.build(day: name, weekday: 0)
      assert_not day.valid?
      assert_includes day.errors[:day], "must be one of the listed workouts"
    end
  end

  test "legs and lower are the same workout, in any split" do
    assert_equal %w[Legs Lower], WorkoutDay.names_for("Lower")
    assert_equal %w[Legs Lower], WorkoutDay.names_for("Legs")
    assert_equal ["Push"], WorkoutDay.names_for("Push")

    legs = @split.workout_days.create!(day: "Legs", weekday: 1)
    push = @split.workout_days.create!(day: "Push", weekday: 2)
    lower = @user.splits.create!(name: "Upper lower").workout_days.create!(day: "Lower", weekday: 1)
    # Legs and Lower on the same date would be one session, so the Lower one is a day earlier
    # and a split has one workout a day, so its Push is on another date too
    logs = [legs.workout_logs.create!(date: Date.current), push.workout_logs.create!(date: Date.current - 2)]
    logs << lower.workout_logs.create!(date: Date.current - 1)
    assert_equal [logs[0], logs[2]], @user.workout_logs.of_workout("Lower").order(:id).to_a
    assert_equal [logs[1]], @user.workout_logs.of_workout("Push").to_a
  end
end
