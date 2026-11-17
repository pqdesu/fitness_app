require "test_helper"

# Covers the chain used to record a workout:
# user -> split -> workout day -> workout exercise -> log -> log exercise -> sets
class WorkoutRecordingTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(email: "lifter@example.com", password: "secret123")
    @split = @user.splits.create!(name: "PPL")
    @day = @split.workout_days.create!(day: "Push", weekday: 1)
    @exercise = Exercise.create!(name: "Bench press")
    @workout_exercise = @day.workout_exercises.create!(exercise: @exercise)
    @log = @day.workout_logs.create!(date: Date.current)
    @log_exercise = @log.workout_log_exercises.create!(workout_exercise: @workout_exercise)
  end

  test "an exercise in use cannot be destroyed" do
    assert_not @exercise.destroy
    assert @exercise.errors[:base].any?
    assert Exercise.exists?(@exercise.id)
  end

  test "an unused exercise can be destroyed" do
    assert Exercise.create!(name: "Squat").destroy
  end

  test "a logged exercise copies its exercise and equipment from the plan" do
    assert_equal [@log_exercise], @exercise.workout_log_exercises.to_a
    assert_equal "Bench press", @log_exercise.name

    planned = @day.workout_exercises.create!(name: "Chest press", equipment: "machine", machine_brand: "Acme")
    entry = @log.workout_log_exercises.create!(workout_exercise: planned)
    assert_equal ["Chest press", "machine", "Acme"], [entry.name, entry.equipment, entry.machine_brand]
  end

  test "an exercise is picked from the catalogue or typed" do
    typed = @day.workout_exercises.create!(name: "  Hack   squat ")
    assert_equal "Hack squat", typed.name
    assert_nil typed.exercise

    picked = @day.workout_exercises.create!(exercise: Exercise.create!(name: "Squat"), name: "ignored")
    assert_equal "Squat", picked.name

    assert_not @day.workout_exercises.build.valid?
    assert_not @day.workout_exercises.build(exercise_id: 0, name: "Ghost").valid?
  end

  test "equipment is free weights or a machine with a brand" do
    lift = @day.workout_exercises.build(name: "Leg press")
    assert_equal "free_weights", lift.equipment
    assert lift.valid?
    assert_equal "Free weights", lift.equipment_label

    lift.equipment = "machine"
    assert_not lift.valid?
    assert lift.errors[:machine_brand].any?
    lift.machine_brand = "Acme"
    assert lift.valid?
    assert_equal "Machine · Acme", lift.equipment_label

    lift.equipment = "free_weights"
    assert lift.valid?
    assert_nil lift.machine_brand

    lift.equipment = "kettlebell"
    assert_not lift.valid?
  end

  test "an exercise can be logged without being planned" do
    entry = @log.workout_log_exercises.create!(name: "Sissy squat")
    assert_nil entry.workout_exercise
    assert_not @log.workout_log_exercises.build.valid?
  end

  test "removing a planned exercise keeps its logged sets" do
    @log_exercise.workout_sets.create!(set_number: 1, reps_completed: 8)
    @workout_exercise.destroy

    assert_nil @log_exercise.reload.workout_exercise
    assert_equal "Bench press", @log_exercise.name
    assert_equal 1, @log_exercise.workout_sets.count
  end

  test "renaming a catalogue exercise renames it in plans and logs" do
    typed = @day.workout_exercises.create!(name: "Hack squat")
    @exercise.update!(name: "Barbell bench press")

    assert_equal "Barbell bench press", @workout_exercise.reload.name
    assert_equal "Barbell bench press", @log_exercise.reload.name
    assert_equal "Hack squat", typed.reload.name
  end

  test "deleting a catalogue exercise keeps logged history" do
    squat = Exercise.create!(name: "Squat")
    entry = @log.workout_log_exercises.create!(exercise: squat)
    assert squat.destroy
    assert_nil entry.reload.exercise
    assert_equal "Squat", entry.name
  end

  test "recorded set numbers must be valid" do
    [{ set_number: 0 }, { reps_completed: -1 }, { reps_completed: 1.5 }, { weight_used: -1 }].each do |attrs|
      record = @log_exercise.workout_sets.build({ set_number: 1, reps_completed: 8, weight_used: 80 }.merge(attrs))
      assert_not record.valid?, "expected #{attrs} to be invalid"
    end
  end

  test "a new set takes the next number for its exercise" do
    first = @log_exercise.workout_sets.create!(reps_completed: 8)
    second = @log_exercise.workout_sets.create!(reps_completed: 8)
    first.destroy
    third = @log_exercise.workout_sets.create!(reps_completed: 8)

    assert_equal [1, 2, 3], [first, second, third].map(&:set_number)
  end

  test "a workout day sits on one weekday of its split" do
    assert_equal "Monday", @day.weekday_name
    assert_not @split.workout_days.build(day: "Pull", weekday: 1).valid?
    assert_not @split.workout_days.build(day: "Pull").valid?
    assert_not @split.workout_days.build(day: "Pull", weekday: 7).valid?
    assert @split.workout_days.build(day: "Pull", weekday: 0).valid?
    assert @user.splits.create!(name: "Other").workout_days.build(day: "Push", weekday: 1).valid?
  end

  test "an exercise is shared, or belongs to the user who created it" do
    other = User.create!(email: "other@example.com", password: "secret123")
    mine = Exercise.create!(name: "Cable fly", user: @user)
    theirs = Exercise.create!(name: "Secret lift", user: other)

    assert @exercise.shared?
    assert_not mine.shared?
    assert_equal [@exercise, mine].sort_by(&:id), Exercise.visible_to(@user).order(:id).to_a
    assert_not_includes Exercise.visible_to(@user), theirs
    assert_equal "Other", mine.group
  end

  test "a set may record zero reps and no weight" do
    assert @log_exercise.workout_sets.build(set_number: 1, reps_completed: 0).valid?
  end

  test "set number is unique per logged exercise in rails and in the database" do
    @log_exercise.workout_sets.create!(set_number: 1, reps_completed: 8)
    duplicate = @log_exercise.workout_sets.build(set_number: 1, reps_completed: 6)

    assert_not duplicate.valid?
    assert_raises(ActiveRecord::RecordNotUnique) { duplicate.save!(validate: false) }
  end

  test "required columns are not null in the database" do
    assert_raises(ActiveRecord::NotNullViolation) do
      WorkoutLog.new(workout_day: @day, user: @user, workout: "Push").save!(validate: false)
    end
  end

  test "user reaches their own logs only" do
    other = User.create!(email: "other@example.com", password: "secret123")
    other_day = other.splits.create!(name: "Upper/Lower").workout_days.create!(day: "Upper", weekday: 1)
    other_log = other_day.workout_logs.create!(date: Date.current)

    assert_equal [@log], @user.workout_logs.to_a
    assert_equal [other_log], other.workout_logs.to_a
    assert_equal @user, @log.user
  end

  test "a log cannot record an exercise planned for a different day" do
    other_day = @split.workout_days.create!(day: "Pull", weekday: 2)
    other_exercise = other_day.workout_exercises.create!(exercise: @exercise)
    entry = @log.workout_log_exercises.build(workout_exercise: other_exercise)

    assert_not entry.valid?
    assert entry.errors[:workout_exercise].any?
  end

  test "a log takes exercises planned for the same workout in another of the user's splits" do
    squat = Exercise.create!(name: "Squat")
    same_workout = @user.splits.create!(name: "Other").workout_days.create!(day: "Push", weekday: 3)
    assert @log.workout_log_exercises.build(workout_exercise: same_workout.workout_exercises.create!(exercise: squat)).valid?

    someone = User.create!(email: "other@example.com", password: "secret123")
    theirs = someone.splits.create!(name: "Theirs").workout_days.create!(day: "Push", weekday: 1)
    entry = @log.workout_log_exercises.build(workout_exercise: theirs.workout_exercises.create!(exercise: squat))
    assert_not entry.valid?
    assert entry.errors[:workout_exercise].any?
  end

  test "an exercise is on a day once and in a logged workout once" do
    again = @day.workout_exercises.build(exercise: @exercise)
    assert_not again.valid?
    assert_includes again.errors[:base], "Bench press is already on this day"

    twice = @log.workout_log_exercises.build(exercise: @exercise)
    assert_not twice.valid?
    assert_includes twice.errors[:base], "Bench press is already in this workout"

    # the database refuses what slips past the check (two requests at the same moment)
    assert_raises(ActiveRecord::RecordNotUnique) { again.save!(validate: false) }
    assert_raises(ActiveRecord::RecordNotUnique) { twice.save!(validate: false) }
  end

  test "there is one session per workout per day, shared by every split" do
    twin = @day.workout_logs.build(date: Date.current)
    assert_not twin.valid?
    assert_includes twin.errors[:date], "already has a Push workout logged"
    assert @day.workout_logs.build(date: Date.current - 1).valid?

    # the same workout in another split joins today's session, and the same exercise its entry
    other = @user.splits.create!(name: "Other").workout_days.create!(day: "Push", weekday: 3)
    same_lift = other.workout_exercises.create!(exercise: @exercise)
    new_lift = other.workout_exercises.create!(exercise: Exercise.create!(name: "Dips"))
    assert_equal @log, other.log_on(Date.current)
    assert_equal @log_exercise, same_lift.entry_on!(Date.current)
    assert_nil new_lift.entry_on(Date.current)
    entry = new_lift.entry_on!(Date.current)
    assert_equal [@log, new_lift], [entry.workout_log, entry.workout_exercise]
    assert_equal 1, @user.workout_logs.count

    # moving a session onto a date that has one is refused; other changes to it are not
    earlier = @day.workout_logs.create!(date: Date.current - 7)
    assert_not earlier.update(date: Date.current)
    assert earlier.reload.update(notes: "Felt strong")
  end

  test "weights keep three decimals" do
    set = @log_exercise.workout_sets.create!(reps_completed: 5, weight_used: "1.111")
    assert_equal BigDecimal("1.111"), set.reload.weight_used
    set.update!(weight_used: "82.5")
    assert_equal BigDecimal("82.5"), set.reload.weight_used
    assert_not set.update(weight_used: 100_000)
  end

  test "an exercise name is unique in the catalogue and among a user's own" do
    assert_not Exercise.new(name: " bench  PRESS ").valid?
    own = Exercise.create!(name: "Bench press", user: @user)
    assert_not Exercise.new(name: "bench press", user: @user).valid?
    assert own.update(muscle_group: "Chest")
  end
end
