# Mock data for trying the app out: last week's sessions, already recorded.
#
#   bin/rails mock:last_week                  every user
#   bin/rails mock:last_week EMAIL=me@x.com   one user
#   bin/rails mock:clear                      removes the workouts it logged
#
# For every workout day of every split it logs that day's session on its weekday of last week:
# three sets of each exercise. A day that has no exercises yet first gets a typical plan for its
# workout, taken from the catalogue. Safe to run again: a day already logged that date is skipped.
namespace :mock do
  note = "Mock data"

  # Exercise => [muscle group, weight in kg (nil = bodyweight), reps of the first set]
  lifts = {
    "Bench press" => ["Chest", 80, 8],
    "Incline dumbbell press" => ["Chest", 28, 10],
    "Overhead press" => ["Shoulders", 50, 8],
    "Lateral raise" => ["Shoulders", 10, 14],
    "Triceps pushdown" => ["Triceps", 32.5, 12],
    "Pull-up" => ["Back", nil, 9],
    "Barbell row" => ["Back", 70, 10],
    "Lat pulldown" => ["Back", 60, 11],
    "Barbell curl" => ["Biceps", 35, 10],
    "Squat" => ["Legs", 110, 6],
    "Romanian deadlift" => ["Legs", 100, 8],
    "Leg press" => ["Legs", 180, 12],
    "Calf raise" => ["Calves", 60, 15],
    "Plank" => ["Core", nil, 60]
  }
  lower = ["Squat", "Romanian deadlift", "Leg press", "Calf raise"]
  plans = {
    "Push" => ["Bench press", "Incline dumbbell press", "Overhead press", "Lateral raise", "Triceps pushdown"],
    "Pull" => ["Pull-up", "Barbell row", "Lat pulldown", "Barbell curl"],
    "Legs" => lower,
    "Lower" => lower,
    "Upper" => ["Bench press", "Barbell row", "Overhead press", "Lat pulldown", "Barbell curl", "Triceps pushdown"],
    "Anterior" => ["Squat", "Bench press", "Overhead press", "Leg press"],
    "Posterior" => ["Romanian deadlift", "Pull-up", "Barbell row", "Calf raise"],
    "Full Body" => ["Squat", "Bench press", "Barbell row", "Overhead press", "Plank"]
  }
  users = -> { ENV["EMAIL"].present? ? [User.find_by!(email: ENV["EMAIL"])] : User.all.to_a }

  desc "Log last week's workouts for every split (EMAIL=... for one user)"
  task last_week: :environment do
    last_sunday = Date.current.beginning_of_week(:sunday) - 7

    users.call.each do |user|
      user.workout_days.includes(:split).where.not(weekday: nil).order(:split_id, :weekday).each do |day|
        date = last_sunday + day.weekday
        label = "#{user.email} · #{day.split.name} · #{day.day} on #{date.strftime('%a %b %-d')}"
        next puts("skipped  #{label} (already logged)") if day.workout_logs.exists?(date: date)

        WorkoutLog.transaction do
          if day.workout_exercises.empty?
            plans.fetch(day.day).each do |name|
              exercise = Exercise.shared.find_or_create_by!(name: name) { |e| e.muscle_group = lifts.fetch(name).first }
              day.workout_exercises.create!(exercise: exercise)
            end
          end

          log = day.workout_logs.create!(date: date, notes: note)
          day.workout_exercises.order(:id).each do |planned|
            _, weight, reps = lifts.fetch(planned.name, [nil, 20, 10])
            entry = log.workout_log_exercises.create!(workout_exercise: planned)
            # Reps drop a little set after set, as they do when the weight stays the same.
            3.times { |i| entry.workout_sets.create!(weight_used: weight, reps_completed: reps - i) }
          end
        end
        puts "logged   #{label}"
      end
    end
  end

  desc "Delete the workouts logged by mock:last_week (EMAIL=... for one user)"
  task clear: :environment do
    users.call.each do |user|
      logs = user.workout_logs.where(notes: note).destroy_all
      puts "#{user.email}: #{logs.size} mock workouts deleted"
    end
  end
end
