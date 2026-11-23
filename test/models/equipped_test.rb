require "test_helper"

class EquippedTest < ActiveSupport::TestCase
  test "the label says which free weight, or the machine's type, which machine and brand" do
    lift = WorkoutExercise.new(name: "Fly")
    assert_equal "Free weights", lift.equipment_label
    lift.equipment_name = "Dumbbell"
    assert_equal "Dumbbell", lift.equipment_label
    lift.assign_attributes(equipment: "machine", equipment_name: nil, machine_brand: "Acme")
    assert_equal "Machine · Acme", lift.equipment_label
    lift.assign_attributes(machine_type: "Plate loaded", equipment_name: "Pec Deck", machine_brand: "MTorture")
    assert_equal "Plate loaded Pec Deck · MTorture", lift.equipment_label
    lift.equipment = "bodyweight"
    assert_equal "Bodyweight", lift.equipment_label
  end

  test "only a machine keeps a type and a brand, bodyweight keeps no name, and a changed kind drops the old name" do
    user = User.create!(email: "lifter@example.com", password: "secret123")
    day = user.splits.create!(name: "PPL").workout_days.create!(day: "Push", weekday: 1)
    lift = day.workout_exercises.create!(name: "Press", equipment: "machine", machine_type: "Pin loaded",
                                         equipment_name: "Chest press", machine_brand: "Hammer")

    lift.update!(equipment: "free_weights")
    assert_equal [nil, nil, nil], [lift.equipment_name, lift.machine_type, lift.machine_brand]
    lift.update!(equipment_name: " Dumbbell ")
    assert_equal "Dumbbell", lift.equipment_name
    lift.update!(equipment: "bodyweight", equipment_name: "Dumbbell")
    assert_nil lift.equipment_name
  end
end
