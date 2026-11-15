class WorkoutSet < ApplicationRecord
  belongs_to :workout_log_exercise

  validates :set_number, presence: true,
                         numericality: { only_integer: true, greater_than: 0 },
                         uniqueness: { scope: :workout_log_exercise_id }
  # Zero is allowed: a failed attempt is still a recorded set.
  validates :reps_completed, presence: true,
                             numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  # Optional: bodyweight sets have no weight.
  validates :weight_used, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
end
