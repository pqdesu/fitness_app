class PagesController < ApplicationController
  skip_before_action :authenticate_user!, only: [ :home ]

  def home
    return unless user_signed_in?

    @splits_count = current_user.splits.count
    @active_split = current_user.current_split
    @active_days = @active_split ? @active_split.workout_days.order(:weekday, :id) : []

    @today = Date.current
    @today_workout = @active_days.find { |day| day.weekday == @today.wday }
    @last_log = last_session_of(@today_workout) if @today_workout
    @recent_logs = current_user.workout_logs
                               .includes(workout_day: :split, workout_log_exercises: :workout_sets)
                               .order(date: :desc, id: :desc).limit(5)
    @logs_count = current_user.workout_logs.count
    @sets_count = WorkoutSet.joins(workout_log_exercise: :workout_log)
                            .where(workout_logs: { user_id: current_user.id }).count
  end

  private

  # "Last time": the most recent earlier session of the same workout, usually last week's.
  # It is looked up by workout, not by split, so changing or deleting a split keeps the comparison.
  def last_session_of(workout_day)
    current_user.workout_logs
                .of_workout(workout_day.day)
                .where(date: ...@today)
                .includes(workout_day: :split, workout_log_exercises: :workout_sets)
                .order(date: :desc, id: :desc).first
  end
end
