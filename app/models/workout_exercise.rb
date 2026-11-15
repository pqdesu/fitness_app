# An exercise on a workout day. The plan only says which exercise;
# sets, reps and weight are recorded when the user trains (see WorkoutSet).
class WorkoutExercise < ApplicationRecord
  include Lift

  belongs_to :workout_day
  # Removing an exercise from the plan keeps what was already logged for it.
  has_many :workout_log_exercises, dependent: :nullify
end
