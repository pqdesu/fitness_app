require "test_helper"

# db/seeds/data.yml: seed:dump merges the database into the file, db:seed loads what is missing.
class SeedDataTest < ActiveSupport::TestCase
  setup do
    travel_to Time.zone.local(2026, 11, 18, 12) # a Wednesday
    @path = Pathname(Dir.mktmpdir).join("data.yml")
    @user = User.create!(email: "lifter@example.com", password: "secret123", time_zone: "Asia/Tokyo")
    @bench = Exercise.create!(name: "Bench press", muscle_group: "Chest")
    @fly = @user.exercises.create!(name: "Pec fly", muscle_group: "Chest")
    @split = @user.splits.create!(name: "UL")
    @upper = @split.workout_days.create!(day: "Upper", weekday: 1)
    @lower = @split.workout_days.create!(day: "Lower", weekday: 3)
    @upper.workout_exercises.create!(exercise: @bench)
    @upper.workout_exercises.create!(exercise: @fly, equipment: "machine", machine_type: "Plate loaded", equipment_name: "Pec deck",
                                     machine_brand: "Hammer")
    EquipmentItem.create!(name: "Pec deck", kind: "machine")
    @fly.update!(unilateral: true, equipment: "machine", machine_brand: "Hammer")
    @user.update!(active_split: @split)
    @warm_up = SetTag.create!(name: "Warm-up")
  end

  teardown { FileUtils.rm_rf(@path.dirname) }

  def log_upper(date, notes: nil)
    log = @upper.workout_logs.create!(date:, notes:)
    @upper.workout_exercises.each do |planned|
      entry = log.workout_log_exercises.create!(workout_exercise: planned)
      entry.workout_sets.create!(reps_completed: 8, weight_used: "62.125", set_tags: [@warm_up])
      entry.workout_sets.create!(reps_completed: 6, notes: "Bodyweight")
    end
    log
  end

  test "what is dumped loads back into an empty database the same, and loading twice adds nothing" do
    log_upper(Date.new(2026, 11, 16)).update_column(:rest_day, true)
    @split.move_for_week!(@lower, 5, Date.current) # Lower on Friday this week
    SeedData.dump(@path)
    first = @path.read

    [WorkoutLog, WorkoutDayMove, Split, Exercise, User, EquipmentItem, SetTag].each { |model| model.find_each(&:destroy!) }
    assert_equal 0, WorkoutSet.count

    2.times { SeedData.load(@path) }
    user = User.sole
    assert_equal ["lifter@example.com", "Asia/Tokyo", "UL"], [user.email, user.time_zone, user.active_split.name]
    assert user.valid_password?("admin123456")
    log = user.workout_logs.sole
    assert log.rest_day?
    assert_equal @upper.weekday, log.workout_day.weekday
    assert_equal 4, user.workout_sets.count
    assert_equal BigDecimal("62.125"), user.workout_sets.maximum(:weight_used)
    entry = log.workout_log_exercises.find_by(name: "Pec fly")
    assert_equal ["Plate loaded Pec deck · Hammer", "Pec fly"], [entry.equipment_label, entry.exercise.name]
    assert entry.exercise.unilateral?
    assert_equal "Machine · Hammer", entry.exercise.equipment_label
    assert_equal [["Pec deck", "machine"]], EquipmentItem.pluck(:name, :kind)
    assert_equal [["Warm-up"]] * 2, user.workout_sets.where(weight_used: "62.125").map { |set| set.set_tags.map(&:name) }
    assert_equal user, entry.exercise.user
    assert_equal entry.workout_exercise.workout_day, log.workout_day
    assert_equal [[Date.new(2026, 11, 15), 5]], WorkoutDayMove.pluck(:week_start, :weekday)

    SeedData.dump(@path)
    assert_equal first, @path.read, "a database loaded from the file dumps the same file"
  end

  test "a set's rest goes into the file and comes back, measured or about so many minutes" do
    first, second = log_upper(Date.new(2026, 11, 16)).workout_log_exercises.order(:id).map { |entry| entry.workout_sets.find_by(set_number: 2) }
    first.update!(rest_seconds: 135)
    second.update!(rest_seconds: 180, rest_approx: true)
    SeedData.dump(@path)

    [WorkoutLog, WorkoutDayMove, Split, Exercise, User, EquipmentItem, SetTag].each { |model| model.find_each(&:destroy!) }
    SeedData.load(@path)
    assert_equal [[nil, false], [nil, false], [135, false], [180, true]],
                 WorkoutSet.pluck(:rest_seconds, :rest_approx).sort_by { |rest, _| rest || 0 }
  end

  test "a dump keeps what the file had and adds what is new; mock workouts are left out" do
    old = log_upper(Date.new(2026, 11, 9))
    SeedData.dump(@path)

    old.destroy!
    log_upper(Date.new(2026, 11, 16))
    @lower.workout_logs.create!(date: Date.new(2026, 11, 11), notes: "Mock data")
    @split.update!(name: "Upper Lower")
    SeedData.dump(@path)

    data = YAML.safe_load(@path.read)
    user = data["users"].sole
    assert_equal ["2026-11-09", "2026-11-16"], user["workouts"].pluck("date")
    assert_equal ["UL", "Upper Lower"], user["splits"].pluck("name"), "a renamed split is a new one; the old name stays"
    assert_equal [1, 2], user["workouts"].last["exercises"].first["sets"].pluck("number")
    assert_equal ["Bench press"], data["exercises"].pluck("name")
  end
end
