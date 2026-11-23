# Totals over some logged workouts (a day, a week): how many workouts, exercises and sets, the
# heaviest weight lifted and the time of cardio. It reads the logs' loaded exercises, sets and cardio
# rows, so give it logs loaded with WorkoutLog.with_sets and it asks the database for nothing more.
class WorkoutSummary
  def initialize(logs)
    @logs = Array(logs)
  end

  def workouts
    @logs.size
  end

  # Exercises that have at least one set or cardio row, each counted once however many workouts it was done in.
  def exercises
    lifts.map(&:name).uniq.size
  end

  def sets
    lifts.sum { |lift| lift.workout_sets.size }
  end

  # The heaviest weight of any set; nil when only bodyweight sets (or none) were recorded. A
  # bodyweight exercise's weight is only what was added or taken off, so it is not a top weight.
  def top_weight
    lifts.reject(&:bodyweight?).flat_map(&:workout_sets).filter_map(&:weight_used).max
  end

  # The time of every cardio row, in seconds.
  def cardio_seconds
    lifts.sum { |lift| lift.cardio_entries.sum(&:duration_seconds) }
  end

  def sets_in(log)
    log.workout_log_exercises.sum { |lift| lift.workout_sets.size }
  end

  private

  def lifts
    @lifts ||= @logs.flat_map(&:workout_log_exercises).select { |lift| lift.workout_sets.any? || lift.cardio_entries.any? }
  end
end
