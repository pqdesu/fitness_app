class WorkoutSet < ApplicationRecord
  belongs_to :workout_log_exercise

  validates :set_number, :reps_completed, presence: true
  validates :set_number, uniqueness: { scope: :workout_log_exercise_id }
end
