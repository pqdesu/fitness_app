class WorkoutDay < ApplicationRecord
  belongs_to :split
  has_one :user, through: :split
  has_many :workout_exercises, dependent: :destroy
  has_many :exercises, through: :workout_exercises
  has_many :workout_logs, dependent: :destroy

  validates :day, presence: true
  # 0 = Sunday .. 6 = Saturday, as in Date#wday. One workout per weekday in a split.
  validates :weekday, inclusion: { in: 0..6, message: "must be a day of the week" },
                      uniqueness: { scope: :split_id, message: "already has a workout in this split" }

  def weekday_name
    Date::DAYNAMES[weekday] if weekday
  end
end
