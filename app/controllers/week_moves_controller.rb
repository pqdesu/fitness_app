# Moves a workout of a split to another weekday for this week only (see WorkoutDayMove).
# The split's plan is not changed. It returns to the page it was sent from: the dashboard or Today.
class WeekMovesController < ApplicationController
  before_action :set_split

  # workout_day_id goes to weekday (today or later this week). With open, the workout day is
  # opened afterwards: that is "Move to today" on a rest day, where the next step is to train it.
  def create
    day = @split.workout_days.find_by(id: params[:workout_day_id])
    weekday = Integer(params[:weekday], exception: false)
    today = Date.current
    error = day ? @split.week_move_error(day, weekday, today) : "choose a workout"
    return redirect_back_or_to(root_path, alert: "Not moved: #{error}.") if error

    from = @split.week_plan(today).key(day)
    other = @split.move_for_week!(day, weekday, today)
    notice = "#{day.day} is on #{Date::DAYNAMES[weekday]} this week"
    notice += ", and #{other.day} on #{Date::DAYNAMES[from]}" if other && from
    notice += ". Next week follows the plan again."
    return redirect_to(workout_day_path(day), notice:) if params[:open].present?

    redirect_back_or_to root_path, notice:
  end

  # Back to the plan for this week.
  def destroy
    @split.clear_week_moves(Date.current)
    redirect_back_or_to root_path, notice: "This week is back to the plan.", status: :see_other
  end

  private

  def set_split
    @split = current_user.splits.find(params[:split_id])
  end
end
