class WorkoutSetsController < ApplicationController
  def create
    entry = WorkoutLogExercise.joins(workout_log: { workout_day: :split })
                              .where(splits: { user_id: current_user.id })
                              .find(params[:workout_log_exercise_id])
    workout_set = entry.workout_sets.new(workout_set_params)
    if workout_set.save
      redirect_to workout_log_path(entry.workout_log_id, anchor: "entry-#{entry.id}"), notice: "Set #{workout_set.set_number} logged."
    else
      redirect_to workout_log_path(entry.workout_log_id, anchor: "entry-#{entry.id}"),
                  alert: "Set not logged: #{workout_set.errors.full_messages.to_sentence}."
    end
  end

  def destroy
    workout_set = WorkoutSet.joins(workout_log_exercise: { workout_log: { workout_day: :split } })
                            .where(splits: { user_id: current_user.id })
                            .find(params[:id])
    workout_set.destroy
    entry = workout_set.workout_log_exercise
    redirect_to workout_log_path(entry.workout_log_id, anchor: "entry-#{entry.id}"), notice: "Set deleted.", status: :see_other
  end

  private

  def workout_set_params
    params.require(:workout_set).permit(:set_number, :reps_completed, :weight_used, :notes)
  end
end
