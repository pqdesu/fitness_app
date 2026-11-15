class WorkoutDaysController < ApplicationController
  before_action :set_split, only: [:new, :create]
  before_action :set_workout_day, only: [:show, :edit, :update, :destroy]

  def show
    @workout_exercises = @workout_day.workout_exercises.includes(:exercise).order(:id)
    @sets_today = WorkoutSet.joins(workout_log_exercise: :workout_log)
                            .where(workout_logs: { workout_day_id: @workout_day.id, date: Date.current })
                            .group("workout_log_exercises.workout_exercise_id").count
    @picker_exercises = Exercise.visible_to(current_user).order(:name)
    @logs = @workout_day.workout_logs.includes(workout_log_exercises: :workout_sets).order(date: :desc, id: :desc)
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
      render :new, status: :unprocessable_entity
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
      render :edit, status: :unprocessable_entity
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
    params.require(:workout_day).permit(:day, :weekday)
  end
end
