# Totals over some logged workouts (a day, a week): how many workouts, exercises and sets, and the
# heaviest weight lifted. It reads the logs' loaded exercises and sets, so give it logs loaded with
# `includes(workout_log_exercises: :workout_sets)` and it asks the database for nothing more.
class WorkoutSummary
  def initialize(logs)
    @logs = Array(logs)
  end

  def workouts
    @logs.size
  end

  # Exercises that have at least one set, each counted once however many workouts it was done in.
  def exercises
    lifts.map(&:name).uniq.size
  end

  def sets
    lifts.sum { |lift| lift.workout_sets.size }
  end

  # The heaviest weight of any set; nil when only bodyweight sets (or none) were recorded.
  def top_weight
    lifts.flat_map(&:workout_sets).filter_map(&:weight_used).max
  end

  def sets_in(log)
    log.workout_log_exercises.sum { |lift| lift.workout_sets.size }
  end

  private

  def lifts
    @lifts ||= @logs.flat_map(&:workout_log_exercises).select { |lift| lift.workout_sets.any? }
  end
end
