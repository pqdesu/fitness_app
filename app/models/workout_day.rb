class WorkoutDay < ApplicationRecord
  belongs_to :split
  has_one :user, through: :split
  has_many :workout_exercises, dependent: :destroy
  has_many :exercises, through: :workout_exercises
  # Logged workouts belong to the user: they stay when the day is deleted.
  has_many :workout_logs, dependent: :nullify

  # A workout day is one of a fixed set of workouts, not a name the user types. That keeps a
  # workout comparable over time: a Push session is the same workout in whichever split it was done.
  NAMES = ["Push", "Pull", "Legs", "Lower", "Upper", "Anterior", "Posterior", "Full Body"].freeze
  # Two names for the same workout.
  SAME_WORKOUT = [%w[Legs Lower]].freeze

  validates :day, inclusion: { in: NAMES, message: "must be one of the listed workouts" }

  # Every name the given workout goes by, e.g. "Lower" => ["Legs", "Lower"].
  def self.names_for(name)
    SAME_WORKOUT.find { |names| names.include?(name) } || [name]
  end
  # 0 = Sunday .. 6 = Saturday, as in Date#wday. One workout per weekday in a split.
  validates :weekday, inclusion: { in: 0..6, message: "must be a day of the week" },
                      uniqueness: { scope: :split_id, message: "already has a workout in this split" }

  def weekday_name
    Date::DAYNAMES[weekday] if weekday
  end
end
