class WorkoutDaysController < ApplicationController
  include ExercisePicker
  include LoggingDate

  before_action :set_split, only: [:new, :create]
  before_action :set_workout_day, only: [:show, :edit, :update, :destroy]

  # The workout: the exercises planned for the day, and those added to this session while training.
  def show
    @workout_exercises = @workout_day.workout_exercises.includes(:exercise).order(:id)
    @date = logging_date(@workout_day)
    # Sets recorded on that date per exercise, read from that day's session of this workout.
    log = current_user.workout_logs.with_sets.session_of(@workout_day.day, @date)
    entries = @workout_exercises.to_h { |planned| [planned.id, log && planned.entry_in(log)] }
    @sets_logged = entries.transform_values { |entry| entry&.workout_sets&.size.to_i }
    @extra_entries = log ? log.workout_log_exercises.sort_by(&:id) - entries.values : []
  end

  def new
    # Coming from an empty circle of the week, the weekday is already chosen.
    free = (0..6).to_a - @split.workout_days.pluck(:weekday)
    weekday = text_param(:weekday).presence&.to_i
    @workout_day = @split.workout_days.new(weekday: free.include?(weekday) ? weekday : free.first)
  end

  def create
    @workout_day = @split.workout_days.new(workout_day_params)
    if @workout_day.save
      redirect_to split_path(@split, anchor: "day-#{@workout_day.id}"), notice: "Workout day created. Plan its exercises."
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit
    @split = @workout_day.split
  end

  def update
    if @workout_day.update(workout_day_params)
      redirect_to split_path(@workout_day.split, anchor: "day-#{@workout_day.id}"), notice: "Workout day updated."
    else
      @split = @workout_day.split
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @workout_day.destroy
    redirect_to @workout_day.split, notice: "Workout day deleted.", status: :see_other
  end

  private

  def set_split
    @split = current_user.splits.find(params[:split_id])
  end

  def set_workout_day
    @workout_day = current_user.workout_days.find(params[:id])
  end

  def workout_day_params
    params.expect(workout_day: [:day, :weekday])
  end
end
