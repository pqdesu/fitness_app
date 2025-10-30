class Exercise < ApplicationRecord
  has_many :workout_exercises
  has_many :workout_days, through: :workout_exercises
  has_many :workout_log_exercises

  validates :name, presence: true
end
