# The app's base data, kept in git as db/seeds/data.yml so every checkout starts from the same
# users' plans and logged workouts. The app reads dates (this week, last time, the calendar), so
# the file keeps every workout ever dumped: new data is added to it, nothing old is dropped.
#
#   bin/rails seed:dump   merges the development database into the file (SeedData::Dumper)
#   bin/rails db:seed     creates what the file has and the database does not (SeedData::Loader)
#
# Records are matched by what identifies them to a user, never by id, so the file reads the same
# on every machine: a user by email, an exercise by name, a split by name, a workout day by
# weekday, a move by its week, a workout by workout and date, a set by its number.
#
# Mock workouts (notes "Mock data…", from bin/rails mock:last_week) are never written to the file.
# Passwords are never written: a user the file creates gets SEED_USER_PASSWORD (in development
# "admin123456", like the admin of db/seeds.rb).
module SeedData
  PATH = Rails.root.join("db/seeds/data.yml")
  MOCK_NOTES = "Mock data%".freeze

  def self.dump(path = PATH) = Dumper.new(path).dump
  def self.load(path = PATH) = Loader.new(path).load

  def self.mock_workouts_in_database
    WorkoutLog.where("notes LIKE ?", MOCK_NOTES).count
  end

  def self.read(path)
    path = Pathname(path)
    return {} unless path.exist?

    YAML.safe_load(path.read, permitted_classes: [Date]) || {}
  end

  # What a file (or the merged data) holds, for the tasks to print.
  def self.counts(data)
    users = Array(data["users"])
    workouts = users.flat_map { |user| Array(user["workouts"]) }
    {
      users: users.size,
      splits: users.sum { |user| Array(user["splits"]).size },
      workouts: workouts.size,
      sets: workouts.sum { |log| Array(log["exercises"]).sum { |entry| Array(entry["sets"]).size } }
    }
  end

  def self.describe(counts)
    counts.map { |name, count| "#{count} #{name}" }.join(", ")
  end
end
