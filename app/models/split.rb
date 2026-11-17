class Split < ApplicationRecord
  belongs_to :user
  has_many :workout_days, dependent: :destroy
  has_many :workout_day_moves, through: :workout_days

  validates :name, presence: true

  def active?
    user.current_split == self
  end

  # The week the given date is in, as it is trained: weekday (0 = Sunday) => workout day. It is
  # the plan, with the workouts moved for that week only (see WorkoutDayMove) on their new days.
  def week_plan(date)
    moved = moves_of_week(date).pluck(:workout_day_id, :weekday).to_h
    workout_days.order(:weekday, :id).each_with_object({}) do |day, plan|
      weekday = moved.fetch(day.id, day.weekday)
      plan[weekday] ||= day if weekday
    end
  end

  # Why the workout day cannot go to that weekday in the week of today, or nil when it can.
  def week_move_error(day, weekday, today)
    return "choose a day from today to Saturday" unless weekday && (today.wday..6).cover?(weekday)

    logs = user.workout_logs.where(date: today.all_week(:sunday), workout_day_id: workout_day_ids)
    return "#{day.day} is already logged this week" if logs.any? { |log| log.workout_day_id == day.id }

    "today already has a workout logged in #{name}" if weekday == today.wday && logs.any? { |log| log.date == today }
  end

  # Puts the workout day on that weekday for the week of the given date only. A workout already
  # on that weekday takes the day this one leaves, so the week still has one workout a day.
  # Returns that other workout day, or nil when the weekday was free.
  def move_for_week!(day, weekday, date)
    plan = week_plan(date)
    from = plan.key(day)
    other = plan[weekday]
    return if from == weekday

    transaction do
      place(day, weekday, date)
      place(other, from, date) if other
    end
    other
  end

  # Back to the plan for the week of the given date.
  def clear_week_moves(date)
    moves_of_week(date).destroy_all
  end

  def moves_of_week(date)
    workout_day_moves.where(week_start: WorkoutDayMove.week_start_of(date))
  end

  private

  # A workout back on its planned weekday needs no move.
  def place(day, weekday, date)
    move = day.workout_day_moves.find_or_initialize_by(week_start: WorkoutDayMove.week_start_of(date))
    if weekday == day.weekday
      move.destroy if move.persisted?
    else
      move.update!(weekday: weekday)
    end
  end
end
