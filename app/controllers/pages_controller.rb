class PagesController < ApplicationController
  skip_before_action :authenticate_user!, only: [:home]

  def home
    return unless user_signed_in?

    @splits_count = current_user.splits.count
    @active_split = current_user.current_split
    @active_days = @active_split ? @active_split.workout_days.order(:weekday, :id) : []

    @today = Date.current
    @today_workout = @active_days.find { |day| day.weekday == @today.wday }
    if @today_workout
      # Once today's session has sets, the Today box shows them; "last time" stays as a link.
      @today_log = session_of(@today_workout).where(date: @today).order(:id).first
      @last_log = session_of(@today_workout).where(date: ...@today).order(date: :desc, id: :desc).first
    end
    # The calendar marks the days a workout was logged on, and each opens what was recorded.
    calendar_dates = helpers.month_weeks(@today).flatten
    @logs_by_date = current_user.workout_logs.where(date: calendar_dates.first..calendar_dates.last)
                                .order(:id).group_by(&:date)
    @recent_logs = current_user.workout_logs
                               .includes(workout_day: :split, workout_log_exercises: :workout_sets)
                               .order(date: :desc, id: :desc).limit(5)
    @logs_count = current_user.workout_logs.count
    @sets_count = WorkoutSet.joins(workout_log_exercise: :workout_log)
                            .where(workout_logs: { user_id: current_user.id }).count
  end

  private

  # Sessions of the same workout as the given day. They are looked up by workout, not by split,
  # so changing or deleting a split keeps today's sets and the "last time" comparison.
  def session_of(workout_day)
    current_user.workout_logs.of_workout(workout_day.day)
                .includes(workout_day: :split, workout_log_exercises: :workout_sets)
  end
end
