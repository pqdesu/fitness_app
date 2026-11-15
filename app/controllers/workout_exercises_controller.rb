class WorkoutExercisesController < ApplicationController
  before_action :set_workout_exercise, only: [:edit, :update, :destroy]

  def create
    workout_day = current_user.workout_days.find(params[:workout_day_id])
    workout_exercise = workout_day.workout_exercises.new(workout_exercise_params)
    if workout_exercise.save
      redirect_to workout_day, notice: "#{workout_exercise.exercise.name} added to the plan."
    else
      redirect_to workout_day, alert: "Exercise not added: #{workout_exercise.errors.full_messages.to_sentence}."
    end
  end

  def edit
  end

  def update
    if @workout_exercise.update(workout_exercise_params)
      redirect_to @workout_exercise.workout_day, notice: "Planned exercise updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @workout_exercise.destroy
    redirect_to @workout_exercise.workout_day, notice: "Exercise removed from the plan.", status: :see_other
  end

  private

  def set_workout_exercise
    @workout_exercise = WorkoutExercise.joins(workout_day: :split)
                                       .where(splits: { user_id: current_user.id })
                                       .find(params[:id])
  end

  def workout_exercise_params
    params.require(:workout_exercise).permit(:exercise_id, :sets, :reps, :target_weight)
  end
end
