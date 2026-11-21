# A tag an admin keeps for sets: warm-up, assisted… A user marks a set with any of them; deleting a
# tag takes it off every set that had it.
class SetTag < ApplicationRecord
  has_many :workout_set_tags, dependent: :delete_all
  has_many :workout_sets, through: :workout_set_tags

  normalizes :name, with: ->(name) { name.squish.presence }

  validates :name, presence: true, length: { maximum: 30 }, uniqueness: { case_sensitive: false }

  # "Warm-up", "Warmup", "warm up": the tag an exercise's first set starts with when the user asks
  # for it (users.auto_warm_up).
  def warm_up?
    name.downcase.gsub(/[^a-z]/, "") == "warmup"
  end
end
