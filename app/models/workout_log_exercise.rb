class WorkoutLogExercise < ApplicationRecord
  include Lift

  belongs_to :workout_log
  # Optional: an exercise can be logged without having been planned.
  belongs_to :workout_exercise, optional: true
  has_many :workout_sets, dependent: :destroy

  # Runs before Lift's normalisation, so the copied values are the ones that get checked.
  before_validation :copy_from_plan, on: :create, prepend: true

  validate :workout_exercise_belongs_to_logged_day

  private

  # An entry started from the plan takes the plan's exercise and equipment,
  # so nothing has to be retyped at the gym.
  def copy_from_plan
    return if workout_exercise.nil? || name.present? || exercise_id.present?

    self.exercise = workout_exercise.exercise
    self.name = workout_exercise.name
    self.equipment = workout_exercise.equipment
    self.machine_brand = workout_exercise.machine_brand
  end

  # A log is for one workout day, so it can only link to exercises planned for that day.
  def workout_exercise_belongs_to_logged_day
    return if workout_log.nil? || workout_exercise.nil?
    return if workout_exercise.workout_day_id == workout_log.workout_day_id

    errors.add(:workout_exercise, "must belong to the same workout day as the log")
  end
end
