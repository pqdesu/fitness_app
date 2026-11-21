# Shared by planned exercises (WorkoutExercise) and logged exercises (WorkoutLogExercise).
#
# The exercise is picked from the shared catalogue or from the user's own exercises (exercise_id).
# Its name is also stored on the row, so logged history survives the exercise being deleted.
# The equipment is free weights, a machine with a brand the user types, or bodyweight (a set's
# weight is then what is added to the body, or taken off it when negative: see WorkoutSet).
module Lift
  extend ActiveSupport::Concern

  EQUIPMENT = { "free_weights" => "Free weights", "machine" => "Machine", "bodyweight" => "Bodyweight" }.freeze

  included do
    belongs_to :exercise, optional: true

    before_validation :normalize_lift

    validates :name, presence: true, length: { maximum: 80 }
    validates :exercise, presence: { message: "is not available" }, if: -> { exercise_id.present? }
    validates :equipment, inclusion: { in: EQUIPMENT.keys }
    validates :machine_brand, presence: true, length: { maximum: 60 }, if: :machine?
  end

  def machine?
    equipment == "machine"
  end

  def bodyweight?
    equipment == "bodyweight"
  end

  def equipment_label
    machine? ? "Machine · #{machine_brand}" : EQUIPMENT.fetch(equipment, equipment)
  end

  private

  def normalize_lift
    # The linked exercise decides the name.
    self.name = exercise.name if exercise
    self.name = name.to_s.squish.presence
    self.machine_brand = machine? ? machine_brand.to_s.squish.presence : nil
  end
end
