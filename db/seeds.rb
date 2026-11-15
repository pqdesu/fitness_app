# Idempotent: safe to run more than once.

# Admin account. Override with ADMIN_EMAIL / ADMIN_PASSWORD; the defaults are for local development only.
admin_email = ENV.fetch("ADMIN_EMAIL", "admin@example.com")
admin_password = ENV.fetch("ADMIN_PASSWORD") do
  raise "Set ADMIN_PASSWORD to seed the admin user" if Rails.env.production?

  "admin123456"
end

admin = User.find_or_initialize_by(email: admin_email)
admin.password = admin_password if admin.new_record?
admin.admin = true
admin.save!
puts "Admin user: #{admin.email}"

# Starter exercise catalogue
[
  ["Bench press", "Chest", "Barbell"],
  ["Incline dumbbell press", "Chest", "Dumbbell"],
  ["Overhead press", "Shoulders", "Barbell"],
  ["Lateral raise", "Shoulders", "Dumbbell"],
  ["Triceps pushdown", "Triceps", "Cable"],
  ["Pull-up", "Back", "Bodyweight"],
  ["Barbell row", "Back", "Barbell"],
  ["Lat pulldown", "Back", "Cable"],
  ["Barbell curl", "Biceps", "Barbell"],
  ["Squat", "Legs", "Barbell"],
  ["Romanian deadlift", "Legs", "Barbell"],
  ["Leg press", "Legs", "Machine"],
  ["Calf raise", "Calves", "Machine"],
  ["Plank", "Core", "Bodyweight"]
].each do |name, muscle_group, equipment|
  Exercise.find_or_create_by!(name: name) do |exercise|
    exercise.muscle_group = muscle_group
    exercise.equipment = equipment
  end
end
puts "Exercises in catalogue: #{Exercise.count}"
