# The base data of db/seeds/data.yml (see lib/seed_data.rb).
#
#   bin/rails seed:dump   adds the development database's data to the file, keeping what it had
#   bin/rails seed:load   creates what the file has and the database does not (db:seed does it too)
namespace :seed do
  desc "Merge the database's users, plans and logged workouts into db/seeds/data.yml"
  task dump: :environment do
    mock = SeedData.mock_workouts_in_database
    puts "Note: #{mock} mock workouts are in the database; they are not written to the file." if mock.positive?
    puts "#{SeedData::PATH.relative_path_from(Rails.root)}: #{SeedData.describe(SeedData.dump)}"
  end

  desc "Create what db/seeds/data.yml has and the database does not"
  task load: :environment do
    puts "Loaded #{SeedData::PATH.relative_path_from(Rails.root)}: #{SeedData.describe(SeedData.load)}"
  end
end
