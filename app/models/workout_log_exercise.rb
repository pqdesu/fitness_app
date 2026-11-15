class WorkoutLogExercise < ApplicationRecord
  belongs_to :workout_log
  belongs_to :workout_exercise
  has_many :workout_sets, dependent: :destroy

  validate :workout_exercise_belongs_to_logged_day

  private

  # A log is for one workout day, so it can only record exercises planned for that day.
  def workout_exercise_belongs_to_logged_day
    return if workout_log.nil? || workout_exercise.nil?
    return if workout_exercise.workout_day_id == workout_log.workout_day_id

    errors.add(:workout_exercise, "must belong to the same workout day as the log")
  end
end
