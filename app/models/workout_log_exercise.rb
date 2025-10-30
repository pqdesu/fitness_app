class WorkoutLogExercise < ApplicationRecord
  belongs_to :workout_log
  belongs_to :workout_exercise
end
