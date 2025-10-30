class WorkoutLogExercise < ApplicationRecord
  belongs_to :workout_log
  belongs_to :workout_exercise

  validates :sets_completed, :reps_completed, presence: true
end
