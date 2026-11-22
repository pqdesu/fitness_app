module SeedData
  # Creates every record of db/seeds/data.yml that the database does not have yet. Records that
  # are already there are left as they are, so running it again changes nothing.
  class Loader
    include Catalogue

    def initialize(path)
      @path = Pathname(path)
    end

    def load
      data = SeedData.read(@path)
      ActiveRecord::Base.transaction do
        Array(data["equipment"]).each { |item| find_or_create_equipment(item) }
        Array(data["set_tags"]).each { |item| named(SetTag.all, item["name"]) || SetTag.create!(name: item["name"]) }
        Array(data["exercises"]).each { |item| find_or_create_exercise(Exercise.where(user_id: nil), item) }
        Array(data["users"]).each { |item| load_user(item) }
      end
      SeedData.counts(data)
    end

    private

    def load_user(item)
      user = User.find_by(email: item["email"]) ||
             User.create!(email: item["email"], password: user_password, admin: item["admin"] || false,
                          timer_auto_start: item["timer_auto_start"] || false, auto_warm_up: item["auto_warm_up"] || false)
      user.update_column(:time_zone, item["time_zone"]) if user.time_zone.blank? && item["time_zone"].present?

      # "Today" of the date rules is the user's own day.
      Time.use_zone(user.time_zone.presence || Time.zone) do
        Array(item["exercises"]).each { |exercise| find_or_create_exercise(user.exercises, exercise) }
        Array(item["splits"]).each { |split| load_split(user, split) }
        Array(item["workouts"]).sort_by { |log| log["date"].to_s }.each { |log| load_workout(user, log) }
      end

      active = item["active_split"] && split_named(user, item["active_split"])
      user.update!(active_split: active) if active && user.active_split_id.nil?
    end

    def user_password
      ENV.fetch("SEED_USER_PASSWORD") do
        raise "Set SEED_USER_PASSWORD to create the users of #{@path.basename}" if Rails.env.production?

        "admin123456"
      end
    end

    def split_named(user, name)
      user.splits.order(:id).find_by(name:)
    end

    def exercise_for(user, item)
      case item["exercise"]
      when "shared" then named(Exercise.where(user_id: nil), item["name"])
      when "own" then named(user.exercises, item["name"])
      end
    end

    def lift_attributes(user, item)
      equipment_attributes(item).merge(name: item["name"], exercise: exercise_for(user, item))
    end

    def day_of(user, split_name, weekday)
      return if split_name.nil? || weekday.nil?

      split_named(user, split_name)&.workout_days&.find_by(weekday:)
    end

    def load_split(user, item)
      split = split_named(user, item["name"]) || user.splits.create!(name: item["name"])
      days = Array(item["days"]).map do |day_item|
        day = split.workout_days.find_by(weekday: day_item["weekday"]) ||
              split.workout_days.create!(day: day_item["day"], weekday: day_item["weekday"])
        Array(day_item["exercises"]).each do |lift|
          named(day.workout_exercises, lift["name"]) || day.workout_exercises.create!(lift_attributes(user, lift))
        end
        [day, day_item]
      end
      # Moves last: adding a workout day clears the split's moves.
      days.each { |day, day_item| Array(day_item["moves"]).each { |move| load_move(day, move) } }
    end

    def load_move(day, move)
      week_start = Date.iso8601(move["week_start"].to_s)
      day.workout_day_moves.find_or_create_by!(week_start:) { |row| row.weekday = move["weekday"] }
    end

    def load_workout(user, item)
      date = Date.iso8601(item["date"].to_s)
      log = user.workout_logs.session_of(item["workout"], date) || create_workout(user, item, date)
      Array(item["exercises"]).each { |entry_item| load_entry(user, log, entry_item) }
    rescue ActiveRecord::RecordInvalid => e
      raise ActiveRecord::RecordInvalid.new(e.record), "#{item['workout']} on #{item['date']} of #{user.email}: #{e.message}"
    end

    def create_workout(user, item, date)
      log = user.workout_logs.create!(workout_day: day_of(user, item["split"], item["weekday"]),
                                      workout: item["workout"], date:, notes: item["notes"])
      # Kept as it was decided when the workout was logged, not worked out again here, and the
      # timer's times as they were (an automatic start would have stamped the loading time).
      times = %w[started_at ended_at paused_at].to_h { |key| [key, item[key] && Time.iso8601(item[key].to_s)] }
      log.update_columns(times.merge("rest_day" => item["rest_day"] || false, "paused_seconds" => item["paused_seconds"].to_i))
      log
    end

    def load_entry(user, log, item)
      entry = named(log.workout_log_exercises, item["name"]) || create_entry(user, log, item)
      Array(item["sets"]).each do |set|
        next if entry.workout_sets.exists?(set_number: set["number"])

        entry.workout_sets.create!(set_number: set["number"], reps_completed: set["reps"], notes: set["notes"],
                                   weight_used: set["weight"] && BigDecimal(set["weight"].to_s),
                                   rest_seconds: set["rest"], rest_approx: set["rest_approx"] || false,
                                   set_tags: SetTag.where(name: Array(set["tags"])))
      end
    end

    def create_entry(user, log, item)
      planned_in = item["planned_in"]
      day = planned_in && day_of(user, planned_in["split"], planned_in["weekday"])
      planned = day && named(day.workout_exercises, item["name"])
      log.workout_log_exercises.create!(lift_attributes(user, item).merge(workout_exercise: planned, notes: item["notes"]))
    end
  end
end
