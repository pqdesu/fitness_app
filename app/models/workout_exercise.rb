# An exercise on a workout day. The plan only says which exercise;
# sets, reps and weight are recorded when the user trains (see WorkoutSet).
class WorkoutExercise < ApplicationRecord
  include Lift
  include Positioned

  belongs_to :workout_day
  # Removing an exercise from the plan keeps what was already logged for it.
  has_many :workout_log_exercises, dependent: :nullify

  # Checked when adding only, so rows that were doubled before this rule can still be edited.
  validate :not_already_on_day, on: :create

  # Where this exercise's sets of that date are recorded, or nil when there are none yet.
  def cardio? = exercise&.cardio? || false

  # Cardio has no equipment: it says so wherever a lift's equipment is written.
  def equipment_label = cardio? ? "Cardio" : super

  def entry_on(date)
    log = workout_day.log_on(date)
    entry_in(log) if log
  end

  # The same, creating the session and the entry when the first set of the day is added.
  def entry_on!(date)
    log = workout_day.log_on(date) || workout_day.workout_logs.create!(date:)
    entry_in(log) || log.workout_log_exercises.create!(workout_exercise: self)
  end

  # This exercise's entry in a logged workout: the one started from this plan row, or else the
  # one of the same exercise (started from another split's plan, or added to the workout by hand).
  # It reads the log's loaded exercises, so asking for every exercise of a day costs one query.
  def entry_in(log)
    log.workout_log_exercises
       .select { |entry| entry.workout_exercise_id == id || (exercise_id && entry.exercise_id == exercise_id) }
       .min_by { |entry| [entry.workout_exercise_id == id ? 0 : 1, entry.id] }
  end

  private

  def siblings = WorkoutExercise.where(workout_day_id:)

  def not_already_on_day
    return if workout_day.nil? || exercise_id.nil?
    return unless workout_day.workout_exercises.where(exercise_id:).exists?

    errors.add(:base, "#{name} is already on this day")
  end
end
