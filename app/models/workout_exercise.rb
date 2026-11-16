# An exercise on a workout day. The plan only says which exercise;
# sets, reps and weight are recorded when the user trains (see WorkoutSet).
class WorkoutExercise < ApplicationRecord
  include Lift

  belongs_to :workout_day
  # Removing an exercise from the plan keeps what was already logged for it.
  has_many :workout_log_exercises, dependent: :nullify

  # Checked when adding only, so rows that were doubled before this rule can still be edited.
  validate :not_already_on_day, on: :create

  # The user's session of this exercise's workout on the given date. There is one session per
  # workout per day, whichever split it was started from (see WorkoutLog).
  def log_on(date)
    workout_day.split.user.workout_logs.of_workout(workout_day.day).where(date: date).order(:id).first
  end

  # Where this exercise's sets of that date are recorded, or nil when there are none yet.
  def entry_on(date)
    log = log_on(date)
    entry_in(log) if log
  end

  # The same, creating the session and the entry when the first set of the day is added.
  def entry_on!(date)
    log = log_on(date) || workout_day.workout_logs.create!(date: date)
    entry_in(log) || log.workout_log_exercises.create!(workout_exercise: self)
  end

  # This exercise's entry in a logged workout: the one started from this plan row, or else the
  # one of the same exercise (started from another split's plan, or added to the workout by hand).
  def entry_in(log)
    entries = log.workout_log_exercises
    matching = entries.where(workout_exercise_id: id)
    matching = matching.or(entries.where(exercise_id: exercise_id)) if exercise_id
    matching.min_by { |entry| [entry.workout_exercise_id == id ? 0 : 1, entry.id] }
  end

  private

  def not_already_on_day
    return if workout_day.nil? || exercise_id.nil?
    return unless workout_day.workout_exercises.where(exercise_id: exercise_id).exists?

    errors.add(:base, "#{name} is already on this day")
  end
end
