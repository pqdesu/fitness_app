class WorkoutSetsController < ApplicationController
  # Adds a set. From an exercise of a workout day it goes into today's workout,
  # which is created on the first set; from a logged workout it goes into that entry.
  def create
    workout_set = nil
    back = nil

    WorkoutSet.transaction do
      if params[:workout_exercise_id]
        planned = WorkoutExercise.joins(workout_day: :split).where(splits: { user_id: current_user.id })
                                 .find(params[:workout_exercise_id])
        entry = todays_entry_for(planned)
        back = workout_exercise_path(planned)
      else
        entry = WorkoutLogExercise.joins(:workout_log).where(workout_logs: { user_id: current_user.id })
                                  .find(params[:workout_log_exercise_id])
        back = workout_log_path(entry.workout_log_id, anchor: "entry-#{entry.id}")
      end

      workout_set = entry.workout_sets.new(workout_set_params)
      # A set that is not saved must not leave an empty workout behind.
      raise ActiveRecord::Rollback unless workout_set.save
    end

    if workout_set.persisted?
      redirect_to back, notice: "Set #{workout_set.set_number} added."
    else
      redirect_to back, alert: "Set not added: #{workout_set.errors.full_messages.to_sentence}."
    end
  end

  # Corrects the weight or reps of a set that is already recorded.
  def update
    workout_set = own_set
    message = if workout_set.update(params.require(:workout_set).permit(:reps_completed, :weight_used))
      { notice: "Set #{workout_set.set_number} updated." }
    else
      { alert: "Set not updated: #{workout_set.errors.full_messages.to_sentence}." }
    end
    redirect_back fallback_location: entry_path(workout_set), status: :see_other, **message
  end

  def destroy
    workout_set = own_set
    workout_set.destroy
    redirect_back fallback_location: entry_path(workout_set), notice: "Set deleted.", status: :see_other
  end

  private

  def own_set
    WorkoutSet.joins(workout_log_exercise: :workout_log)
              .where(workout_logs: { user_id: current_user.id }).find(params[:id])
  end

  def entry_path(workout_set)
    entry = workout_set.workout_log_exercise
    workout_log_path(entry.workout_log_id, anchor: "entry-#{entry.id}")
  end

  def todays_entry_for(planned)
    workout_log = planned.workout_day.workout_logs.where(date: Date.current).order(:id).first_or_create!
    workout_log.workout_log_exercises.where(workout_exercise: planned).order(:id).first_or_create!
  end

  def workout_set_params
    params.require(:workout_set).permit(:set_number, :reps_completed, :weight_used, :notes)
  end
end
