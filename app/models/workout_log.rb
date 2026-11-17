# One session of a workout (Push, Legs, ...) on a date. It is the user's own record: it starts
# from a workout day of a split, but stays when that day or the whole split is deleted.
class WorkoutLog < ApplicationRecord
  belongs_to :user
  # The day of the split it was logged from; gone once that day or its split is deleted.
  belongs_to :workout_day, optional: true
  has_many :workout_log_exercises, dependent: :destroy
  has_many :workout_exercises, through: :workout_log_exercises

  before_validation :copy_from_workout_day, on: :create
  before_validation :mark_rest_day, on: :create

  validates :date, presence: true
  validates :notes, length: { maximum: 2000 }
  validates :workout, inclusion: { in: WorkoutDay::NAMES }
  # One session per workout per day: sets added from any split go into the same log.
  validate :only_session_of_workout_that_day, if: -> { new_record? || date_changed? || workout_changed? }

  # A second workout on the same day only comes from another split: a split has one workout a day.
  validate :only_workout_of_its_split_that_day, if: -> { new_record? || date_changed? }

  # Sessions of this same workout, whichever split they were done in.
  scope :of_workout, ->(name) { where(workout: WorkoutDay.names_for(name)) }
  # With everything WorkoutSummary and the pages read, so they ask the database for nothing more.
  scope :with_sets, -> { includes(workout_log_exercises: :workout_sets) }

  # The session of that workout on that date among these logs (a user's), or nil.
  def self.session_of(workout, date)
    of_workout(workout).where(date:).order(:id).first
  end

  private

  def only_session_of_workout_that_day
    return if user.nil? || date.nil? || workout.blank?
    return unless user.workout_logs.of_workout(workout).where(date:).where.not(id:).exists?

    errors.add(:date, "already has a #{workout} workout logged")
  end

  def only_workout_of_its_split_that_day
    # The same workout twice is already reported by the rule above.
    return if user.nil? || date.nil? || workout_day.nil? || errors[:date].any?

    other = user.workout_logs.joins(:workout_day).where(date:).where.not(id:)
                .find_by(workout_days: { split_id: workout_day.split_id })
    return if other.nil?

    errors.add(:base, "#{other.workout} is already logged on #{I18n.l(date, format: :long)} in #{workout_day.split.name}. " \
                      "A second workout that day has to come from another split")
  end

  # A workout logged on a weekday its own split has nothing on that week (the plan, with that
  # week's moves): a rest day the user trained on anyway. Decided when the session starts and
  # kept, so editing the split later does not rewrite what the user did that day. The split
  # itself is not changed.
  def mark_rest_day
    return if workout_day.nil? || date.nil?

    self.rest_day = workout_day.split.rest_day?(date)
  end

  def copy_from_workout_day
    return if workout_day.nil?

    self.user ||= workout_day.split.user
    self.workout ||= workout_day.day
  end
end
