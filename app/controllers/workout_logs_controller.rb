class WorkoutLogsController < ApplicationController
  before_action :set_workout_log, only: [:show, :update, :destroy]

  def index
    @workout_logs = current_user.workout_logs
                                .includes(workout_day: :split, workout_log_exercises: :workout_sets)
                                .order(date: :desc, id: :desc)
  end

  def show
    @workout_day = @workout_log.workout_day
    @log_exercises = @workout_log.workout_log_exercises
                                 .includes(:workout_sets, workout_exercise: :exercise).order(:id)
    @unlogged_exercises = @workout_day.workout_exercises.includes(:exercise)
                                      .where.not(id: @log_exercises.map(&:workout_exercise_id)).order(:id)
  end

  # Starts a workout for a day: one log, with an entry for every exercise planned that day.
  def create
    workout_day = current_user.workout_days.find(params[:workout_day_id])
    workout_log = workout_day.workout_logs.new(date: Date.current)

    WorkoutLog.transaction do
      workout_log.save!
      workout_day.workout_exercises.order(:id).each do |workout_exercise|
        workout_log.workout_log_exercises.create!(workout_exercise: workout_exercise)
      end
    end
    redirect_to workout_log_path(workout_log), notice: "Workout started. Log your sets as you go."
  rescue ActiveRecord::RecordInvalid => e
    redirect_to workout_day, alert: "Workout not started: #{e.record.errors.full_messages.to_sentence}."
  end

  def update
    if @workout_log.update(workout_log_params)
      redirect_to workout_log_path(@workout_log), notice: "Workout details saved."
    else
      redirect_to workout_log_path(@workout_log),
                  alert: "Details not saved: #{@workout_log.errors.full_messages.to_sentence}."
    end
  end

  def destroy
    @workout_log.destroy
    redirect_to workout_logs_path, notice: "Workout deleted.", status: :see_other
  end

  private

  def set_workout_log
    @workout_log = current_user.workout_logs.find(params[:id])
  end

  def workout_log_params
    params.require(:workout_log).permit(:date, :notes)
  end
end
