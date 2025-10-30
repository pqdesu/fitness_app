class WorkoutExercise < ApplicationRecord
  belongs_to :workout_day
  belongs_to :exercise
  has_many :workout_log_exercises, dependent: :destroy

  validates :sets, :reps, presence: true
end
