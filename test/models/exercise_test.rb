require "test_helper"

class ExerciseTest < ActiveSupport::TestCase
  test "Calves is no longer a muscle group: calf exercises are Legs (owner, 2026-11-28)" do
    assert_not_includes Exercise::MUSCLE_GROUPS, "Calves"
    assert_includes Exercise::MUSCLE_GROUPS, "Legs"

    exercise = Exercise.new(name: "Seated calf raise", muscle_group: "Calves")
    assert_not exercise.valid?
    assert_includes exercise.errors[:muscle_group], "must be one of the listed muscle groups"
  end
end
