class WorkoutLogExercise < ApplicationRecord
  include Lift

  belongs_to :workout_log
  # Optional: an exercise can be logged without having been planned.
  belongs_to :workout_exercise, optional: true
  has_many :workout_sets, dependent: :destroy

  # Runs before Lift's normalisation, so the copied values are the ones that get checked.
  before_validation :copy_from_plan, on: :create, prepend: true

  validate :workout_exercise_fits_the_log
  # Checked when adding only, so entries that were doubled before this rule can still be edited.
  validate :not_already_in_log, on: :create

  before_validation { self.notes = notes.to_s.strip.presence }

  # The heaviest set of this exercise; between equal weights (or bodyweight sets), the most reps.
  def top_set
    workout_sets.max_by { |set| [set.weight_used || 0, set.reps_completed] }
  end

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

  # A log is one session of a workout, so it only links to exercises planned for that workout:
  # the day it was started from, or the same workout in another of the user's splits.
  def workout_exercise_fits_the_log
    return if workout_log.nil? || workout_exercise.nil?

    day = workout_exercise.workout_day
    return if day.id == workout_log.workout_day_id
    return if day.split.user_id == workout_log.user_id && WorkoutDay.names_for(workout_log.workout).include?(day.day)

    errors.add(:workout_exercise, "must be planned for the same workout as the log")
  end

  def not_already_in_log
    return if workout_log.nil? || exercise_id.nil?
    return unless workout_log.workout_log_exercises.where(exercise_id: exercise_id).exists?

    errors.add(:base, "#{name} is already in this workout")
  end
end
