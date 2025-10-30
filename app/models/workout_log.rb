class WorkoutLog < ApplicationRecord
  belongs_to :workout_day
  has_many :workout_log_exercises, dependent: :destroy
  has_many :workout_exercises, through: :workout_log_exercises

  validates :date, presence: true
end
