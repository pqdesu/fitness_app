class WorkoutDay < ApplicationRecord
  belongs_to :split
  has_many :workout_exercises, dependent: :destroy
  has_many :exercises, through: :workout_exercises
  has_many :workout_logs, dependent: :destroy

  validates :day, presence: true
  validates :order_index, presence: true
end
