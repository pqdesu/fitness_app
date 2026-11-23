# One session of a workout (Push, Legs, ...) on a date. It is the user's own record: it starts
# from a workout day of a split, but stays when that day or the whole split is deleted.
class WorkoutLog < ApplicationRecord
  belongs_to :user
  # The day of the split it was logged from; gone once that day or its split is deleted.
  belongs_to :workout_day, optional: true
  has_many :workout_log_exercises, -> { order(:position, :id) }, dependent: :destroy, inverse_of: :workout_log
  has_many :workout_exercises, through: :workout_log_exercises

  before_validation :copy_from_workout_day, on: :create
  before_validation :mark_rest_day, on: :create
  before_create :start_timer_automatically

  # A workout is logged on the day it is done, so its date is never after today; the earliest
  # date only stops a typo in the year (0001, 20026) from sending a workout where no page shows it.
  EARLIEST_DATE = Date.new(2000, 1, 1)
  # Cardio on a rest day instead of lifting: a logged workout of its own, never a day of a split.
  CARDIO = "Cardio".freeze
  # What a logged workout can be: a split's workouts, or Cardio.
  WORKOUTS = [*WorkoutDay::NAMES, CARDIO].freeze
  validates :date, presence: true
  validate :date_in_range, if: -> { new_record? || date_changed? }
  validates :notes, length: { maximum: 2000 }
  validate :ends_after_start
  validates :workout, inclusion: { in: WORKOUTS }
  # One session per workout per day: sets added from any split go into the same log.
  validate :only_session_of_workout_that_day, if: -> { new_record? || date_changed? || workout_changed? }

  # A second workout on the same day only comes from another split: a split has one workout a day.
  validate :only_workout_of_its_split_that_day, if: -> { new_record? || date_changed? }

  # Sessions of this same workout, whichever split they were done in.
  scope :of_workout, ->(name) { where(workout: WorkoutDay.names_for(name)) }
  # With everything WorkoutSummary and the pages read, so they ask the database for nothing more.
  scope :with_sets, -> { includes(workout_log_exercises: [:workout_sets, :cardio_entries]) }

  # The session of that workout on that date among these logs (a user's), or nil.
  def self.session_of(workout, date)
    of_workout(workout).where(date:).order(:id).first
  end

  # The timer starts on the day the workout is done, so only on today's workout. Once started it
  # pauses, resumes and stops on any day, and the workout keeps its own date.
  def timer_today?
    date == Date.current
  end

  # The timer: started_at is the first start, paused_at when it is paused (empty while it runs),
  # ended_at when it was stopped for good. paused_seconds adds up the time between each Pause and
  # Resume. It runs until Pause or Stop, past midnight too, on the workout's own date. Every
  # time is kept to the second, and shown so, never rounded.
  def timer_running?
    started_at.present? && paused_at.nil? && ended_at.nil?
  end

  def timer_paused?
    paused_at.present? && ended_at.nil?
  end

  # The workout's end by its timer: when it stopped, or else when it was paused (a timer paused
  # and never stopped ends there).
  def timer_end
    ended_at || paused_at
  end

  # The time the timer counted: from start to its end (or now while it runs), less the pauses.
  def recorded_seconds
    ((timer_end || Time.current) - started_at).to_i - paused_seconds if started_at
  end

  def pause_timer
    self.paused_at = Time.current
  end

  # The time since the pause is left out of the workout's time.
  def resume_timer
    self.paused_seconds += (Time.current - paused_at).to_i
    self.paused_at = nil
  end

  # Stopped while paused, it ended when it was paused; the pause after the end is not counted.
  def stop_timer
    self.ended_at = paused_at || Time.current
    self.paused_at = nil
  end

  # Corrects when the workout finished (a timer left running), from a clock time "HH:MM" with the
  # seconds at 0: the first such moment after the start, so 1:00 AM after an 11:16 PM start is the
  # next day. A timer still running or paused stops there. Returns the finish, or nil when the
  # time is not a clock time.
  def finish_at(clock)
    hour, min = clock.to_s.match(/\A([01]?\d|2[0-3]):([0-5]\d)\z/)&.captures&.map(&:to_i)
    return if hour.nil? || started_at.nil?

    finished = started_at.change(hour:, min:)
    finished += 1.day if finished < started_at
    self.paused_at = nil
    self.ended_at = finished
  end

  private

  # With the automatic timer on, opening today's workout already starts it (see WorkoutTimersController);
  # this covers a workout logged another way, such as a set added straight from an exercise page.
  def start_timer_automatically
    self.started_at ||= Time.current if timer_today? && user.timer_auto_start?
  end

  def ends_after_start
    return if ended_at.nil?

    errors.add(:ended_at, "needs a start") if started_at.nil?
    errors.add(:ended_at, "can't be before the start") if started_at && ended_at < started_at
    errors.add(:ended_at, "can't be in the future") if ended_at > Time.current
    # Pauses are kept as a total, so an end that leaves less time than was paused cannot be right.
    return unless started_at && ended_at >= started_at && recorded_seconds.negative?

    errors.add(:ended_at, "leaves less time than was paused")
  end

  def date_in_range
    return if date.nil?

    if date > Date.current
      errors.add(:date, "can't be in the future")
    elsif date < EARLIEST_DATE
      errors.add(:date, "can't be before #{EARLIEST_DATE.year}")
    end
  end

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
