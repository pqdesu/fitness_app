class WorkoutLogsController < ApplicationController
  include Paginated
  include ExercisePicker

  before_action :set_workout_log, only: [:show, :update, :destroy]
  before_action :set_workout, only: [:new, :create]

  # A workout of a split is created by adding the first set of the day (see
  # WorkoutSetsController#create). new and create are for a workout that is not in the split:
  # the user picks one of the fixed workouts on the dashboard, then its exercises.

  # The history, or with ?date=YYYY-MM-DD the workouts of that one day (a calendar day that
  # has several workouts links here).
  def index
    @date = Date.iso8601(params[:date]) if params[:date].present?
    logs = current_user.workout_logs.order(date: :desc, id: :desc)
    logs = logs.where(date: @date) if @date
    @workout_logs = paginate(logs, per: 20).includes(workout_day: :split, workout_log_exercises: :workout_sets)
  rescue Date::Error
    redirect_to workout_logs_path
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

  # Nothing is saved here: the workout only exists once its first exercise is added.
  def new
    return redirect_to(workout_log_path(@todays_log, from: "dashboard")) if @todays_log

    @picker_exercises = Exercise.visible_to(current_user).order(:name)
  end

  # Today's workout of that name, with the exercises chosen in the "Add exercises" modal.
  def create
    exercises, error = picked_exercises
    return redirect_to(new_workout_log_path(workout: @workout), alert: "Nothing added: #{error}.") if error

    log = @todays_log
    WorkoutLog.transaction do
      log ||= current_user.workout_logs.create!(workout: @workout, date: Date.current, rest_day: rest_day_today?)
      exercises.each { |exercise| log.workout_log_exercises.create!(exercise: exercise) }
    end
    redirect_to workout_log_path(log, from: "dashboard"), notice: "#{@workout} workout started. Add your sets."
  rescue ActiveRecord::RecordInvalid => e
    redirect_to new_workout_log_path(workout: @workout), alert: "Nothing added: #{e.record.errors.full_messages.to_sentence}."
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
    # Opened from the dashboard, deleting goes back to the dashboard rather than to History.
    redirect_to (params[:from] == "dashboard" ? root_path : workout_logs_path), notice: "Workout deleted.", status: :see_other
  end

  private

  def set_workout_log
    @workout_log = current_user.workout_logs.find(params[:id])
  end

  def set_workout
    @workout = params[:workout]
    return redirect_to(root_path, alert: "Choose one of the listed workouts.") unless WorkoutDay::NAMES.include?(@workout)

    @todays_log = current_user.workout_logs.of_workout(@workout).where(date: Date.current).order(:id).first
  end

  # A workout outside the split has no day of its own to compare with, so it is a rest day
  # workout when the active split has nothing on today this week.
  def rest_day_today?
    split = current_user.current_split
    split.present? && !split.week_plan(Date.current).key?(Date.current.wday)
  end

  def workout_log_params
    params.require(:workout_log).permit(:date, :notes)
  end
end
