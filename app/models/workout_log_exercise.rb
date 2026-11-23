class WorkoutLogExercise < ApplicationRecord
  include Lift
  include Positioned

  belongs_to :workout_log
  # Optional: an exercise can be logged without having been planned.
  belongs_to :workout_exercise, optional: true
  has_many :workout_sets, dependent: :destroy
  # A cardio exercise's rows (incline, speed, time) in place of sets.
  has_many :cardio_entries, -> { order(:entry_number) }, dependent: :destroy, inverse_of: :workout_log_exercise

  # Runs before Lift's normalisation, so the copied values are the ones that get checked.
  before_validation :copy_from_plan, on: :create, prepend: true

  validate :workout_exercise_fits_the_log
  # Checked when adding only, so entries that were doubled before this rule can still be edited.
  validate :not_already_in_log, on: :create

  normalizes :notes, with: ->(notes) { notes.strip.presence }
  validates :notes, length: { maximum: 500 }

  # The heaviest set of this exercise; between equal weights (or bodyweight sets), the most reps.
  def top_set
    workout_sets.max_by { |set| [set.weight_used || 0, set.reps_completed] }
  end

  # Its rows keep it cardio once its exercise is deleted or moved out of the Cardio group.
  def cardio? = exercise&.cardio? || cardio_entries.any?

  # Cardio has no equipment: it says so wherever a lift's equipment is written.
  def equipment_label = cardio? ? "Cardio" : super

  def rest_running? = rest_started_at.present? && rest_ended_at.nil?

  # The rest stopped with Stop, in seconds, for the set added next; the timer is then done.
  def take_rest!
    seconds = (rest_ended_at - rest_started_at).round if rest_ended_at && rest_started_at
    update!(rest_started_at: nil, rest_ended_at: nil) if rest_started_at
    seconds
  end

  private

  def siblings = WorkoutLogExercise.where(workout_log_id:)

  # An entry started from the plan takes the plan's exercise and equipment,
  # so nothing has to be retyped at the gym.
  def copy_from_plan
    return if workout_exercise.nil? || name.present? || exercise_id.present?

    self.exercise = workout_exercise.exercise
    self.name = workout_exercise.name
    copy_equipment_from(workout_exercise)
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
    return unless workout_log.workout_log_exercises.where(exercise_id:).exists?

    errors.add(:base, "#{name} is already in this workout")
  end
end
