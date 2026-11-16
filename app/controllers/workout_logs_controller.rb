class WorkoutLogsController < ApplicationController
  include Paginated

  before_action :set_workout_log, only: [:show, :update, :destroy]

  # A workout is created by adding the first set of the day (see WorkoutSetsController#create).

  def index
    @workout_logs = paginate(current_user.workout_logs.order(date: :desc, id: :desc), per: 20)
                    .includes(workout_day: :split, workout_log_exercises: :workout_sets)
  end

  def show
    @workout_day = @workout_log.workout_day
    @log_exercises = @workout_log.workout_log_exercises
                                 .includes(:workout_sets, :workout_exercise).order(:id)
    # Nothing is planned any more once the day (or its split) has been deleted.
    # An exercise already in the workout is not offered again, whichever way it got there.
    @unlogged_exercises = if @workout_day
      @workout_day.workout_exercises.order(:id).reject { |planned| planned.entry_in(@workout_log) }
    else
      []
    end
    @picker_exercises = Exercise.visible_to(current_user).order(:name)
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
