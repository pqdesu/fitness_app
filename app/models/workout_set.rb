class WorkoutSet < ApplicationRecord
  belongs_to :workout_log_exercise
  # Tags an admin keeps (warm-up, assisted…), picked for the set; shown in name order.
  has_many :workout_set_tags, dependent: :delete_all
  has_many :set_tags, -> { order(:name) }, through: :workout_set_tags

  # "Add set" does not ask for a number: a new set is the next one for its exercise.
  before_validation :number_set, on: :create

  validates :set_number, presence: true,
                         numericality: { only_integer: true, greater_than: 0 },
                         uniqueness: { scope: :workout_log_exercise_id }
  # Zero is allowed: a failed attempt is still a recorded set. The top is far above any real set
  # (timed holds are stored as seconds, a plank of 60), and keeps a typo out of the
  # 4-byte column, which would otherwise fail in the database instead of in this check.
  MAX_REPS = 1000
  validates :reps_completed, presence: true,
                             numericality: { only_integer: true, greater_than_or_equal_to: 0,
                                             less_than_or_equal_to: MAX_REPS }
  # Optional: bodyweight sets have no weight. On a bodyweight exercise the weight is added to the body
  # ("Bodyweight + 10 kg"), or taken off it when negative (an assisted pull-up, "Bodyweight − 10 kg").
  # The column keeps three decimals (1.125 kg) and goes from -99,999.999 to 99,999.999.
  validates :weight_used, numericality: { greater_than: -100_000, less_than: 100_000 }, allow_nil: true
  validates :weight_used, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true, unless: :bodyweight?

  # The rest before this set, in seconds: measured by the rest timer, or typed in minutes (rest_approx).
  validates :rest_seconds, numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than: 1.day.to_i },
                           allow_nil: true

  normalizes :notes, with: ->(notes) { notes.squish.presence }
  # The same limit as the note field of a set (see workout_sets/_set).
  validates :notes, length: { maximum: 200 }

  def bodyweight?
    workout_log_exercise&.bodyweight? || false
  end

  private

  def number_set
    return if set_number.present? || workout_log_exercise.nil?

    self.set_number = (workout_log_exercise.workout_sets.maximum(:set_number) || 0) + 1
  end
end
