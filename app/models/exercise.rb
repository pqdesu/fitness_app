class Exercise < ApplicationRecord
  # An exercise that is part of someone's program cannot be deleted:
  # destroy returns false and adds an error instead of raising.
  has_many :workout_exercises, dependent: :restrict_with_error
  has_many :workout_days, through: :workout_exercises
  has_many :workout_log_exercises, through: :workout_exercises

  validates :name, presence: true
end
