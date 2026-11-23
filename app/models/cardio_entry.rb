# One row of a cardio exercise: the time it lasted, and the incline (%) and speed (km/h) when the
# machine has them (a bike has no incline). Cardio's counterpart of a WorkoutSet.
class CardioEntry < ApplicationRecord
  belongs_to :workout_log_exercise

  # "Add" does not ask for a number: a new row is the next one of its exercise, as a set is.
  before_validation :number_entry, on: :create

  validates :entry_number, presence: true, numericality: { only_integer: true, greater_than: 0 },
                           uniqueness: { scope: :workout_log_exercise_id }
  validates :duration_seconds, numericality: { only_integer: true, greater_than: 0, less_than: 1.day.to_i }
  # Within the decimal(4, 1) columns; a treadmill's decline is a negative incline.
  validates :incline, numericality: { greater_than: -100, less_than: 100 }, allow_nil: true
  validates :speed, numericality: { greater_than_or_equal_to: 0, less_than: 1000 }, allow_nil: true

  private

  def number_entry
    return if entry_number.present? || workout_log_exercise.nil?

    self.entry_number = (workout_log_exercise.cardio_entries.maximum(:entry_number) || 0) + 1
  end
end
