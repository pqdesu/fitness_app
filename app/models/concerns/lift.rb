# Shared by planned exercises (WorkoutExercise) and logged exercises (WorkoutLogExercise).
#
# The exercise is picked from the shared catalogue or from the user's own exercises (exercise_id).
# Its name is also stored on the row, so logged history survives the exercise being deleted.
# The equipment (Equipped) starts as the exercise's own, and each lift can change it.
module Lift
  extend ActiveSupport::Concern

  included do
    include Equipped

    belongs_to :exercise, optional: true

    # Before Equipped's tidying, so the copied values are the ones that get checked.
    before_validation :start_with_exercise_equipment, on: :create, prepend: true
    before_validation :normalize_lift

    validates :name, presence: true, length: { maximum: 80 }
    validates :exercise, presence: { message: "is not available" }, if: -> { exercise_id.present? }
  end

  private

  # A new lift takes the equipment its exercise starts with, unless it was given its own, or it
  # comes from the plan (a logged exercise then takes the plan's: WorkoutLogExercise#copy_from_plan).
  def start_with_exercise_equipment
    return if exercise.nil? || try(:workout_exercise) || equipment_came_from_user?

    copy_equipment_from(exercise)
  end

  def normalize_lift
    # The linked exercise decides the name.
    self.name = exercise.name if exercise
    self.name = name.to_s.squish.presence
  end
end
