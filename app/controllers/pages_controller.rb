class PagesController < ApplicationController
  skip_before_action :authenticate_user!, only: [ :home ]

  def home
    return unless user_signed_in?

    @splits_count = current_user.splits.count
    @active_split = current_user.current_split
    @active_days = @active_split ? @active_split.workout_days.order(:weekday, :id) : []
    @recent_logs = current_user.workout_logs
                               .includes(workout_day: :split, workout_log_exercises: :workout_sets)
                               .order(date: :desc, id: :desc).limit(5)
    @logs_count = current_user.workout_logs.count
    @sets_count = WorkoutSet.joins(workout_log_exercise: { workout_log: { workout_day: :split } })
                            .where(splits: { user_id: current_user.id }).count
  end
end
