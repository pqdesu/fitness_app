# Planned and logged exercises carry their own name (picked from the catalogue or typed)
# and their own equipment (free weights, or a machine with a typed brand).
class AddTypedNamesAndEquipmentToLifts < ActiveRecord::Migration[7.1]
  LIFT_TABLES = %i[workout_exercises workout_log_exercises].freeze

  def up
    LIFT_TABLES.each do |table|
      add_column table, :name, :string
      add_column table, :equipment, :string, null: false, default: "free_weights"
      add_column table, :machine_brand, :string
    end

    # The catalogue link becomes optional, and a logged exercise can link to it directly.
    add_reference :workout_log_exercises, :exercise, foreign_key: true
    change_column_null :workout_exercises, :exercise_id, true
    # A logged exercise no longer has to come from the plan.
    change_column_null :workout_log_exercises, :workout_exercise_id, true

    execute <<~SQL
      UPDATE workout_exercises
      SET name = exercises.name
      FROM exercises
      WHERE exercises.id = workout_exercises.exercise_id
    SQL
    execute <<~SQL
      UPDATE workout_log_exercises
      SET name = workout_exercises.name, exercise_id = workout_exercises.exercise_id
      FROM workout_exercises
      WHERE workout_exercises.id = workout_log_exercises.workout_exercise_id
    SQL

    LIFT_TABLES.each { |table| change_column_null table, :name, false }

    # Equipment is now chosen per lift, not fixed on the catalogue exercise.
    remove_column :exercises, :equipment
  end

  # Only works while every planned exercise is linked to the catalogue
  # and every logged exercise is linked to the plan.
  def down
    add_column :exercises, :equipment, :string

    change_column_null :workout_log_exercises, :workout_exercise_id, false
    change_column_null :workout_exercises, :exercise_id, false
    remove_reference :workout_log_exercises, :exercise, foreign_key: true

    LIFT_TABLES.each do |table|
      remove_column table, :machine_brand
      remove_column table, :equipment
      remove_column table, :name
    end
  end
end
