# The equipment of a lift (WorkoutExercise, WorkoutLogExercise, through Lift), or the one an
# Exercise starts its lifts with:
# - free weights, maybe which one ("Dumbbell");
# - a machine: its type and which machine, maybe, and the brand the user types
#   ("Plate loaded Pec Deck · MTorture");
# - bodyweight (a set's weight is then added to the body, or taken off it: see WorkoutSet).
# The names are picked from the catalogue an admin keeps (EquipmentItem) and stored as text, like a
# lift's exercise name, so a label stays when an item is deleted from the catalogue.
module Equipped
  extend ActiveSupport::Concern

  EQUIPMENT = { "free_weights" => "Free weights", "machine" => "Machine", "bodyweight" => "Bodyweight" }.freeze
  ATTRIBUTES = %i[equipment equipment_name machine_type machine_brand].freeze

  included do
    before_validation :normalize_equipment

    validates :equipment, inclusion: { in: EQUIPMENT.keys }
    validates :machine_brand, presence: true, length: { maximum: 60 }, if: :machine?
    validates :equipment_name, :machine_type, length: { maximum: 60 }
  end

  def machine?
    equipment == "machine"
  end

  def bodyweight?
    equipment == "bodyweight"
  end

  # "Dumbbell", "Free weights", "Plate loaded Pec Deck · MTorture", "Machine · MTorture", "Bodyweight".
  def equipment_label
    case equipment
    when "machine"
      machine = [machine_type, equipment_name].compact.join(" ").presence || EQUIPMENT["machine"]
      [machine, machine_brand].compact.join(" · ")
    when "free_weights" then equipment_name || EQUIPMENT["free_weights"]
    else EQUIPMENT.fetch(equipment, equipment)
    end
  end

  def copy_equipment_from(source)
    ATTRIBUTES.each { |attribute| self[attribute] = source[attribute] }
  end

  private

  def normalize_equipment
    # A name of the kind left behind (a dumbbell, once the lift is a machine) does not stay.
    self.equipment_name = nil if persisted? && will_save_change_to_equipment? && !will_save_change_to_equipment_name?
    self.equipment_name = bodyweight? ? nil : equipment_name.to_s.squish.presence
    self.machine_type = machine? ? machine_type.to_s.squish.presence : nil
    self.machine_brand = machine? ? machine_brand.to_s.squish.presence : nil
  end
end
