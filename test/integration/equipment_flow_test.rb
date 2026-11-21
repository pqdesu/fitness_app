require "test_helper"

# The equipment catalogue an admin keeps, and a lift's equipment chosen from it.
class EquipmentFlowTest < FlowTest
  setup do
    @dumbbell = EquipmentItem.create!(name: "Dumbbell", kind: "free_weights")
    @pec_deck = EquipmentItem.create!(name: "Pec Deck", kind: "machine")
    @plate = EquipmentItem.create!(name: "Plate loaded", kind: "machine_type")
  end

  test "only an admin manages the equipment catalogue" do
    sign_in @user
    get admin_equipment_items_path
    assert_redirected_to root_path
    post admin_equipment_items_path, params: { equipment_item: { name: "Barbell", kind: "free_weights" } }
    assert_nil EquipmentItem.find_by(name: "Barbell")
    delete admin_equipment_item_path(@dumbbell)
    assert EquipmentItem.exists?(@dumbbell.id)

    sign_in @admin
    get edit_user_registration_path
    assert_select "a[href=?]", admin_equipment_items_path, text: /Equipment/
    get admin_equipment_items_path
    assert_select "#equipment-free-weights .row-title", "Dumbbell"
    assert_select "#equipment-machine .row-title", "Pec Deck"
    assert_select "#equipment-machine-type .row-title", "Plate loaded"
    assert_select "#equipment-free-weights .actions-menu a[href=?]", edit_admin_equipment_item_path(@dumbbell)

    post admin_equipment_items_path, params: { equipment_item: { name: "  Barbell ", kind: "free_weights" } }
    assert_redirected_to admin_equipment_items_path
    assert_equal "free_weights", EquipmentItem.find_by!(name: "Barbell").kind
    # one of each name per kind
    post admin_equipment_items_path, params: { equipment_item: { name: "dumbbell", kind: "free_weights" } }
    assert_response :unprocessable_content
    post admin_equipment_items_path, params: { equipment_item: { name: "Hammer", kind: "tool" } }
    assert_response :unprocessable_content

    patch admin_equipment_item_path(@pec_deck), params: { equipment_item: { name: "Pec deck fly", kind: "machine" } }
    assert_equal "Pec deck fly", @pec_deck.reload.name
    delete admin_equipment_item_path(@dumbbell)
    assert_not EquipmentItem.exists?(@dumbbell.id)
  end

  test "a lift's equipment is picked from the catalogue: which free weight, or the machine's type, which machine and brand" do
    sign_in @user
    day = @user.splits.create!(name: "PPL").workout_days.create!(day: "Push", weekday: Date.current.wday)
    planned = day.workout_exercises.create!(exercise: @bench)
    page = workout_exercise_path(planned, date: Date.current)

    get page
    assert_select "[data-reveal-value=free_weights] input[type=radio][name='workout_exercise[equipment_name]'][value=Dumbbell]", 1
    assert_select "[data-reveal-value=machine] input[type=radio][name='workout_exercise[machine_type]'][value='Plate loaded']", 1
    assert_select "[data-reveal-value=machine] input[type=radio][name='workout_exercise[equipment_name]'][value='Pec Deck']", 1
    assert_select "[data-reveal-value=machine] input[name='workout_exercise[machine_brand]']", 1

    patch page, params: { workout_exercise: { equipment: "free_weights", equipment_name: "Dumbbell" } }
    assert_equal "Dumbbell", planned.reload.equipment_label
    patch page, params: { workout_exercise: { equipment: "machine", machine_type: "Plate loaded", equipment_name: "Pec Deck", machine_brand: "MTorture" } }
    assert_equal "Plate loaded Pec Deck · MTorture", planned.reload.equipment_label
    # the first set's entry takes the plan's equipment
    post workout_exercise_workout_sets_path(planned, date: Date.current), params: { workout_set: { reps_completed: 8, weight_used: 40 } }
    assert_equal "Plate loaded Pec Deck · MTorture", planned.entry_on(Date.current).equipment_label

    # bodyweight has no name or type; free weights again keep no machine detail
    patch page, params: { workout_exercise: { equipment: "free_weights", equipment_name: "" } }
    assert_equal [nil, nil, nil, "Free weights"], planned.reload.then { |p| [p.equipment_name, p.machine_type, p.machine_brand, p.equipment_label] }

    # a name taken out of the catalogue stays on the lift that has it, and is still offered there
    patch page, params: { workout_exercise: { equipment: "free_weights", equipment_name: "Dumbbell" } }
    @dumbbell.destroy!
    get page
    assert_select "input[type=radio][name='workout_exercise[equipment_name]'][value=Dumbbell][checked]", 1
    assert_equal "Dumbbell", planned.reload.equipment_label
  end

  test "a new exercise sets the equipment its lifts start with, and can be unilateral" do
    sign_in @user
    day = @user.splits.create!(name: "PPL").workout_days.create!(day: "Push", weekday: Date.current.wday)
    picker = "#exercise-picker-#{day.id}"

    get split_path(day.split)
    assert_select "#{picker} input[type=radio][name='exercise[equipment]'][value=machine]", 1
    assert_select "#{picker} input[type=checkbox][name='exercise[unilateral]']", 1

    post workout_day_workout_exercises_path(day), params: { exercise: {
      name: "Single arm pec deck", muscle_group: "Chest", unilateral: "1",
      equipment: "machine", machine_type: "Plate loaded", equipment_name: "Pec Deck", machine_brand: "MTorture"
    } }
    exercise = @user.exercises.find_by!(name: "Single arm pec deck")
    assert exercise.unilateral?
    planned = day.workout_exercises.find_by!(exercise:)
    assert_equal "Plate loaded Pec Deck · MTorture", planned.equipment_label

    # the lift can change it; the exercise keeps what new lifts start with
    patch workout_exercise_path(planned, date: Date.current), params: { workout_exercise: { equipment: "bodyweight" } }
    assert_equal "Bodyweight", planned.reload.equipment_label
    assert_equal "Plate loaded Pec Deck · MTorture", exercise.reload.equipment_label

    # added to a workout while training, it starts with the exercise's equipment too
    other = @user.splits.create!(name: "Other").workout_days.create!(day: "Upper", weekday: Date.current.wday)
    post workout_day_workout_log_exercises_path(other, date: Date.current), params: { exercise_ids: [exercise.id] }
    assert_equal "Plate loaded Pec Deck · MTorture", @user.workout_log_exercises.find_by!(exercise:).equipment_label

    # unilateral is shown with the equipment on the exercise's page and the workout's
    get workout_exercise_path(planned, date: Date.current)
    assert_select ".page-header p", "Bodyweight · Unilateral"
    get workout_day_path(day, date: Date.current)
    assert_select ".list-rows .small", /Bodyweight · Unilateral · Chest/
    get exercises_path
    assert_select "td", text: /Single arm pec deck.*Unilateral/m

    # the edit page marks an existing exercise unilateral, or not
    patch exercise_path(exercise), params: { exercise: { unilateral: "0" } }
    assert_not exercise.reload.unilateral?
  end
end
