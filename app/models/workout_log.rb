# One session of a workout (Push, Legs, ...) on a date. It is the user's own record: it starts
# from a workout day of a split, but stays when that day or the whole split is deleted.
class WorkoutLog < ApplicationRecord
  belongs_to :user
  # The day of the split it was logged from; gone once that day or its split is deleted.
  belongs_to :workout_day, optional: true
  has_many :workout_log_exercises, dependent: :destroy
  has_many :workout_exercises, through: :workout_log_exercises

  before_validation :copy_from_workout_day, on: :create

  validates :date, presence: true
  validates :workout, inclusion: { in: WorkoutDay::NAMES }
  # One session per workout per day: sets added from any split go into the same log.
  validate :only_session_of_workout_that_day, if: -> { new_record? || date_changed? || workout_changed? }

  # Sessions of this same workout, whichever split they were done in.
  scope :of_workout, ->(name) { where(workout: WorkoutDay.names_for(name)) }

  private

  def only_session_of_workout_that_day
    return if user.nil? || date.nil? || workout.blank?
    return unless user.workout_logs.of_workout(workout).where(date: date).where.not(id: id).exists?

    errors.add(:date, "already has a #{workout} workout logged")
  end

  def copy_from_workout_day
    return if workout_day.nil?

    self.user ||= workout_day.split.user
    self.workout ||= workout_day.day
  end
end
