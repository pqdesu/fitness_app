class WorkoutDaysController < ApplicationController
  before_action :set_split, only: [:new, :create]
  before_action :set_workout_day, only: [:show, :edit, :update, :destroy]

  def show
    @workout_exercises = @workout_day.workout_exercises.includes(:exercise).order(:id)
    @exercises = Exercise.order(:name)
    @workout_exercise = @workout_day.workout_exercises.new
    @logs = @workout_day.workout_logs.includes(workout_log_exercises: :workout_sets).order(date: :desc, id: :desc)
  end

  def new
    next_index = (@split.workout_days.maximum(:order_index) || 0) + 1
    @workout_day = @split.workout_days.new(order_index: next_index)
  end

  def create
    @workout_day = @split.workout_days.new(workout_day_params)
    if @workout_day.save
      redirect_to @workout_day, notice: "Workout day created. Add the exercises you plan to do."
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
    params.require(:workout_day).permit(:day, :order_index)
  end
end
