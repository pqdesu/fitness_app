class WorkoutExercise < ApplicationRecord
  belongs_to :workout_day
  belongs_to :exercise
  has_many :workout_log_exercises, dependent: :destroy

  validates :sets, :reps, presence: true,
                          numericality: { only_integer: true, greater_than: 0 }
  # Optional: bodyweight exercises have no target weight.
  validates :target_weight, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
end
