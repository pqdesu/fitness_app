# How each day stands on the calendar and the week strip (plain Ruby): :planned (a day of the
# split's week, with that week's moves, from today on or once trained), :missed (a day of the plan
# that passed with nothing logged, from the first workout ever logged on), :extra (trained, but
# not on the plan), or nothing. Dashboard asks it; "logged" is WorkoutLog#logged?.
class DayStates
  def initialize(user, split, today)
    @user = user
    @split = split
    @today = today
    @week_plans = {}
  end

  # date => state, for those dates; logs_by_date is date => workout logs with their exercises loaded.
  def of(dates, logs_by_date)
    dates.each_with_object({}) do |date, states|
      state = state_of(date, logs_by_date.fetch(date, []).any?(&:logged?))
      states[date] = state if state
    end
  end

  # The workout day the plan has on that date (with its week's moves), or nil.
  def day_on(date)
    @week_plans[date.beginning_of_week(:sunday)][date.wday] if planned_on?(date)
  end

  private

  def state_of(date, logged)
    planned = planned_on?(date)
    if planned && (logged || date >= @today) then :planned
    elsif planned && first_log_date && date >= first_log_date then :missed
    elsif logged then :extra
    end
  end

  # Is the date a day of the split's plan in its week? A week is asked once.
  def planned_on?(date)
    return false unless @split

    week = date.beginning_of_week(:sunday)
    @week_plans[week] ||= @split.week_plan(date)
    @week_plans[week].key?(date.wday)
  end

  def first_log_date
    return @first_log_date if defined?(@first_log_date)

    @first_log_date = @user.workout_logs.minimum(:date)
  end
end
