class WorkoutDaysController < ApplicationController
  include ExercisePicker

  before_action :set_split, only: [:new, :create]
  before_action :set_workout_day, only: [:show, :edit, :update, :destroy]

  def show
    @workout_exercises = @workout_day.workout_exercises.includes(:exercise).order(:id)
    # Sets recorded today per exercise, read from today's session of this workout.
    log = current_user.workout_logs.with_sets.session_of(@workout_day.day, Date.current)
    @sets_today = @workout_exercises.to_h do |planned|
      [planned.id, (log && planned.entry_in(log))&.workout_sets&.size.to_i]
    end
  end

  def new
    # Coming from an empty circle of the week, the weekday is already chosen.
    free = (0..6).to_a - @split.workout_days.pluck(:weekday)
    weekday = params[:weekday].presence&.to_i
    @workout_day = @split.workout_days.new(weekday: free.include?(weekday) ? weekday : free.first)
  end

  def create
    @workout_day = @split.workout_days.new(workout_day_params)
    if @workout_day.save
      redirect_to @workout_day, notice: "Workout day created. Add its exercises."
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit
    @split = @workout_day.split
  end

  def update
    if @workout_day.update(workout_day_params)
      redirect_to @workout_day, notice: "Workout day updated."
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
