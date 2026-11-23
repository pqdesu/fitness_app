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
    date = text_param(:date)
    @date = Date.iso8601(date) if date.present?
    logs = current_user.workout_logs.order(date: :desc, id: :desc)
    logs = logs.where(date: @date) if @date
    @workout_logs = paginate(logs, per: 20).with_sets.includes(workout_day: :split)
  rescue Date::Error
    redirect_to workout_logs_path
  end

  def show
    @workout_day = @workout_log.workout_day
    @log_exercises = @workout_log.workout_log_exercises
                                 .includes({ workout_sets: :set_tags }, :cardio_entries, :workout_exercise, :exercise).to_a
    # Nothing is planned any more once the day (or its split) has been deleted.
    # An exercise already in the workout is not offered again, whichever way it got there.
    @unlogged_exercises = if @workout_day
      @workout_day.workout_exercises.reject { |planned| planned.entry_in(@workout_log) }
    else
      []
    end
  end

  # Nothing is saved here: the workout only exists once its first exercise is added.
  def new
    return unless @todays_log

    # Arriving here after a failed create: the reason travels on to the workout's page.
    flash.keep
    redirect_to workout_log_path(@todays_log, from: "dashboard")
  end

  # Today's workout of that name, with the exercises chosen in the "Add exercises" modal.
  def create
    exercises, error = picked_exercises
    return redirect_to(new_workout_log_path(workout: @workout), alert: "Nothing added: #{error}.") if error

    log = @todays_log
    WorkoutLog.transaction do
      log ||= current_user.workout_logs.create!(workout: @workout, date: Date.current, rest_day: rest_day_today?)
      exercises.each { |exercise| log.workout_log_exercises.create!(exercise:) }
    end
    what = cardio_workout? ? "incline, speed and time" : "sets"
    redirect_to workout_log_path(log, from: "dashboard"), notice: "#{@workout} workout started. Add your #{what}."
  rescue ActiveRecord::RecordInvalid => e
    redirect_to new_workout_log_path(workout: @workout), alert: "Nothing added: #{errors_of(e.record)}."
  end

  def update
    if @workout_log.update(workout_log_params)
      redirect_to workout_log_path(@workout_log), notice: "Workout details saved."
    else
      redirect_to workout_log_path(@workout_log),
                  alert: "Details not saved: #{errors_of(@workout_log)}."
    end
  end

  def destroy
    @workout_log.destroy
    # Opened from the dashboard, deleting goes back to the dashboard rather than to History.
    redirect_to (from_dashboard? ? dashboard_path : workout_logs_path), notice: "Workout deleted.", status: :see_other
  end

  private

  def set_workout_log
    @workout_log = current_user.workout_logs.find(params[:id])
  end

  def set_workout
    @workout = params[:workout]
    return redirect_to(root_path, alert: "Choose one of the listed workouts.") unless WorkoutLog::WORKOUTS.include?(@workout)

    @todays_log = current_user.workout_logs.session_of(@workout, Date.current)
  end

  # A workout outside the split has no day of its own to compare with, so it is a rest day
  # workout when the active split has nothing on today this week.
  def rest_day_today?
    split = current_user.current_split
    split.present? && split.rest_day?(Date.current)
  end

  def cardio_workout? = (@workout || @workout_log&.workout) == WorkoutLog::CARDIO

  def workout_log_params
    params.expect(workout_log: [:date, :notes])
  end
end
