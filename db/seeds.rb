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

# Starter exercise catalogue: what users can select instead of typing a name
[
  ["Bench press", "Chest"],
  ["Incline dumbbell press", "Chest"],
  ["Overhead press", "Shoulders"],
  ["Lateral raise", "Shoulders"],
  ["Triceps pushdown", "Triceps"],
  ["Pull-up", "Back"],
  ["Barbell row", "Back"],
  ["Lat pulldown", "Back"],
  ["Barbell curl", "Biceps"],
  ["Squat", "Legs"],
  ["Romanian deadlift", "Legs"],
  ["Leg press", "Legs"],
  ["Calf raise", "Calves"],
  ["Plank", "Core"]
].each do |name, muscle_group|
  Exercise.find_or_create_by!(name: name) do |exercise|
    exercise.muscle_group = muscle_group
  end
end
puts "Exercises in catalogue: #{Exercise.count}"
