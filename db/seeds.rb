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
  ["Plank", "Core"],
  # Cardio is logged as incline, speed and time instead of weight and reps
  ["Treadmill", "Cardio"],
  ["Stationary bike", "Cardio"],
  ["Stair climber", "Cardio"],
  ["Elliptical", "Cardio"]
].each do |name, muscle_group|
  Exercise.find_or_create_by!(name: name) do |exercise|
    exercise.muscle_group = muscle_group
  end
end
puts "Exercises in catalogue: #{Exercise.count}"

# Starter equipment catalogue: what users pick for a lift (an admin adds more on /admin/equipment)
{
  "free_weights" => ["Dumbbell", "Barbell", "Kettlebell", "EZ bar", "Weight plate"],
  "machine" => ["Smith machine", "Chest press", "Pec deck", "Shoulder press", "Lat pulldown", "Seated row",
                "Leg press", "Leg extension", "Leg curl", "Hack squat", "Cable crossover"],
  "machine_type" => ["Plate loaded", "Pin loaded", "Cable"]
}.each do |kind, names|
  names.each { |name| EquipmentItem.where(kind:).where("LOWER(name) = ?", name.downcase).first || EquipmentItem.create!(kind:, name:) }
end
puts "Equipment in catalogue: #{EquipmentItem.count}"

# Starter set tags (an admin adds more on /admin/tags)
["Warm-up", "Assisted", "Drop set"].each do |name|
  SetTag.where("LOWER(name) = ?", name.downcase).first || SetTag.create!(name:)
end
puts "Set tags: #{SetTag.count}"

# The base data: users' plans and logged workouts, kept in db/seeds/data.yml (lib/seed_data.rb).
if SeedData::PATH.exist?
  puts "Base data: #{SeedData.describe(SeedData.load)}"
end
