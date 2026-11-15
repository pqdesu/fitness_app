class WorkoutLogExercisesController < ApplicationController
  def create
    workout_log = current_user.workout_logs.find(params[:workout_log_id])
    entry = workout_log.workout_log_exercises.new(workout_exercise_id: params[:workout_exercise_id])
    if entry.save
      redirect_to workout_log_path(workout_log), notice: "#{entry.workout_exercise.exercise.name} added to this workout."
    else
      redirect_to workout_log_path(workout_log), alert: "Exercise not added: #{entry.errors.full_messages.to_sentence}."
    end
  end

  def destroy
    entry = WorkoutLogExercise.joins(workout_log: { workout_day: :split })
                              .where(splits: { user_id: current_user.id })
                              .find(params[:id])
    entry.destroy
    redirect_to workout_log_path(entry.workout_log_id), notice: "Exercise removed from this workout.", status: :see_other
  end
end
