# The equipment catalogue an admin keeps: the free weights and the machines a lift is done on, and
# the types of machine. Users pick from it (shared/_equipment_fields); a lift stores the names.
class EquipmentItem < ApplicationRecord
  KINDS = { "free_weights" => "Free weights", "machine" => "Machines", "machine_type" => "Machine types" }.freeze

  normalizes :name, with: ->(name) { name.squish.presence }

  validates :name, presence: true, length: { maximum: 60 }, uniqueness: { scope: :kind, case_sensitive: false }
  validates :kind, inclusion: { in: KINDS.keys, message: "must be one of the listed kinds" }

  def self.names(kind)
    where(kind:).order(:name).pluck(:name)
  end
end
