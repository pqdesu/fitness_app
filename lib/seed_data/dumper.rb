module SeedData
  # Writes db/seeds/data.yml: what it already had, with the database's version of every record
  # that is in both, and the database's new records added after the file's own.
  class Dumper
    HEADER = <<~TEXT.freeze
      # Base data of the app, loaded by bin/rails db:seed (lib/seed_data.rb).
      # Rewritten by bin/rails seed:dump, which keeps everything already here and adds what the
      # development database has. Edit by hand only to remove something for good.
    TEXT

    def initialize(path)
      @path = Pathname(path)
    end

    def dump
      merged = Merge.record(SeedData.read(@path), database_data)
      merged["users"].each { |user| user["workouts"]&.sort_by! { |log| [log["date"].to_s, log["workout"]] } }
      @path.dirname.mkpath
      @path.write(HEADER + YAML.dump(Merge.compact(merged)).delete_prefix("---\n"))
      SeedData.counts(merged)
    end

    private

    # --- Reading the database --------------------------------------------------------------

    def database_data
      {
        "equipment" => EquipmentItem.order(:id).map { |item| { "name" => item.name, "kind" => item.kind } },
        "set_tags" => SetTag.order(:id).map { |tag| { "name" => tag.name } },
        "exercises" => Exercise.where(user_id: nil).order(:id).map { |exercise| exercise_data(exercise) },
        "users" => User.order(:id).map { |user| user_data(user) }
      }
    end

    # Only what differs from a new exercise: free weights, not unilateral.
    def exercise_data(exercise)
      { "name" => exercise.name, "muscle_group" => exercise.muscle_group,
        "equipment" => (exercise.equipment unless exercise.equipment == "free_weights"),
        "equipment_name" => exercise.equipment_name, "machine_type" => exercise.machine_type,
        "machine_brand" => exercise.machine_brand, "unilateral" => (true if exercise.unilateral?) }
    end

    def user_data(user)
      {
        "email" => user.email,
        "admin" => user.admin?,
        "time_zone" => user.time_zone,
        "timer_auto_start" => user.timer_auto_start?,
        "auto_warm_up" => user.auto_warm_up?,
        "active_split" => user.active_split&.name,
        "exercises" => user.exercises.order(:id).map { |exercise| exercise_data(exercise) },
        "splits" => user.splits.order(:id).includes(workout_days: [:workout_exercises, :workout_day_moves])
                        .map { |split| split_data(split) },
        "workouts" => real_workouts(user).map { |log| workout_data(log) }
      }
    end

    def real_workouts(user)
      user.workout_logs.where("notes IS NULL OR notes NOT LIKE ?", MOCK_NOTES).order(:date, :id)
          .includes(workout_day: :split,
                    workout_log_exercises: [:exercise, { workout_sets: :set_tags, workout_exercise: { workout_day: :split } }])
    end

    def split_data(split)
      { "name" => split.name, "days" => split.workout_days.sort_by(&:weekday).map { |day| day_data(day) } }
    end

    def day_data(day)
      {
        "day" => day.day,
        "weekday" => day.weekday,
        "exercises" => day.workout_exercises.map { |planned| lift_data(planned) },
        "moves" => day.workout_day_moves.sort_by(&:week_start)
                      .map { |move| { "week_start" => move.week_start.iso8601, "weekday" => move.weekday } }
      }
    end

    # Which exercise a planned or logged lift is: one of the catalogue ("shared"), one of the
    # user's own ("own"), or none any more (only its name is kept).
    def lift_data(lift)
      {
        "name" => lift.name,
        "exercise" => lift.exercise && (lift.exercise.user_id ? "own" : "shared"),
        "equipment" => lift.equipment,
        "equipment_name" => lift.equipment_name,
        "machine_type" => lift.machine_type,
        "machine_brand" => lift.machine_brand
      }
    end

    def workout_data(log)
      {
        "date" => log.date.iso8601,
        "workout" => log.workout,
        "split" => log.workout_day&.split&.name,
        "weekday" => log.workout_day&.weekday,
        "rest_day" => log.rest_day?,
        "notes" => log.notes,
        "started_at" => log.started_at&.iso8601,
        "ended_at" => log.ended_at&.iso8601,
        "paused_at" => log.paused_at&.iso8601,
        "paused_seconds" => log.paused_seconds,
        "exercises" => log.workout_log_exercises.map { |entry| entry_data(entry) }
      }
    end

    def entry_data(entry)
      planned = entry.workout_exercise
      lift_data(entry).merge(
        "planned_in" => planned && { "split" => planned.workout_day.split.name, "weekday" => planned.workout_day.weekday },
        "notes" => entry.notes,
        "sets" => entry.workout_sets.sort_by(&:set_number).map do |set|
          { "number" => set.set_number, "reps" => set.reps_completed,
            "weight" => set.weight_used&.to_s("F"), "notes" => set.notes, "tags" => set.set_tags.map(&:name) }
            # Only a set with a rest says so, so the sets already in the file stay as they are.
            .merge(set.rest_seconds ? { "rest" => set.rest_seconds, "rest_approx" => set.rest_approx } : {})
        end
      )
    end
  end
end
