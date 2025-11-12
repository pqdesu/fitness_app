class WorkoutLogExercise < ApplicationRecord
  belongs_to :workout_log
  belongs_to :workout_exercise
  has_many :workout_sets, dependent: :destroy

end
