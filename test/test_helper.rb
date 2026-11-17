ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)
  end
end

# What every integration test (test/integration/*_flow_test.rb) starts from: an admin, a regular
# user, and two exercises in the shared catalogue.
class FlowTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @admin = User.create!(email: "admin@example.com", password: "secret123", admin: true)
    @user = User.create!(email: "lifter@example.com", password: "secret123")
    @bench = Exercise.create!(name: "Bench press", muscle_group: "Chest")
    @squat = Exercise.create!(name: "Squat", muscle_group: "Legs")
  end
end
