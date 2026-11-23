class Split < ApplicationRecord
  belongs_to :user
  has_many :workout_days, dependent: :destroy
  has_many :workout_day_moves, through: :workout_days

  validates :name, presence: true, length: { maximum: 60 }

  def active?
    user.current_split == self
  end

  # The week the given date is in, as it is trained: weekday (0 = Sunday) => workout day. It is
  # the plan, with the workouts moved for that week only (see WorkoutDayMove) on their new days.
  def week_plan(date)
    moved = moves_of_week(date).pluck(:workout_day_id, :weekday).to_h
    workout_days.order(:weekday, :id).each_with_object({}) do |day, plan|
      weekday = moved.fetch(day.id, day.weekday)
      plan[weekday] ||= day
    end
  end

  # A date this split has nothing on, in that date's week (the plan, with that week's moves).
  def rest_day?(date)
    !week_plan(date).key?(date.wday)
  end

  # Why the workout day cannot go to that weekday in the week of today, or nil when it can.
  def week_move_error(day, weekday, today)
    return "choose a day from today to Saturday" unless weekday && (today.wday..6).cover?(weekday)

    logs = logs_of_week(today)
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

  # The moves of that week that can go back to the plan: not a trained workout (it stays on the
  # day it was trained, as the calendar shows) and not the one it swapped with (two on one day).
  def undoable_week_moves(date)
    moves = moves_of_week(date).includes(:workout_day).to_a
    logged = logs_of_week(date).pluck(:workout_day_id)
    kept_weekdays = moves.select { |move| logged.include?(move.workout_day_id) }.map(&:weekday)
    moves.reject { |move| logged.include?(move.workout_day_id) || kept_weekdays.include?(move.workout_day.weekday) }
  end

  # Back to the plan for the week of the given date.
  def clear_week_moves(date)
    undoable_week_moves(date).each(&:destroy)
  end

  def moves_of_week(date)
    workout_day_moves.where(week_start: WorkoutDayMove.week_start_of(date))
  end

  private

  def logs_of_week(date)
    user.workout_logs.where(date: date.all_week(:sunday), workout_day_id: workout_day_ids)
  end

  # A workout back on its planned weekday needs no move.
  def place(day, weekday, date)
    move = day.workout_day_moves.find_or_initialize_by(week_start: WorkoutDayMove.week_start_of(date))
    if weekday == day.weekday
      move.destroy if move.persisted?
    else
      move.update!(weekday:)
    end
  end
end
