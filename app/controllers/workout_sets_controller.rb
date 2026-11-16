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
        back = workout_exercise_path(planned)
        # One session per workout per day: this joins today's log of the workout if there is one.
        entry = planned.entry_on!(Date.current)
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
  rescue ActiveRecord::RecordInvalid => e
    # Today's workout could not be started: this split already has another workout logged today.
    redirect_to back, alert: "Set not added: #{e.record.errors.full_messages.to_sentence}."
  end

  # Corrects the weight, reps or note of a set that is already recorded.
  def update
    workout_set = own_set
    message = if workout_set.update(params.require(:workout_set).permit(:reps_completed, :weight_used, :notes))
      { notice: "Set #{workout_set.set_number} updated." }
    else
      { alert: "Set not updated: #{workout_set.errors.full_messages.to_sentence}." }
    end
    redirect_to page_of(workout_set), status: :see_other, **message
  end

  def destroy
    workout_set = own_set
    workout_set.destroy
    redirect_to page_of(workout_set), notice: "Set deleted.", status: :see_other
  end

  private

  def own_set
    WorkoutSet.joins(workout_log_exercise: :workout_log)
              .where(workout_logs: { user_id: current_user.id }).find(params[:id])
  end

  # Where the set was edited or deleted from. The exercise page says so itself by sending its
  # workout_exercise_id (see workout_sets/_set); otherwise it was the logged workout page.
  def page_of(workout_set)
    planned = if params[:workout_exercise_id].present?
      WorkoutExercise.joins(workout_day: :split).where(splits: { user_id: current_user.id })
                     .find_by(id: params[:workout_exercise_id])
    end
    return workout_exercise_path(planned) if planned

    entry = workout_set.workout_log_exercise
    workout_log_path(entry.workout_log_id, anchor: "entry-#{entry.id}")
  end

  def workout_set_params
    params.require(:workout_set).permit(:set_number, :reps_completed, :weight_used, :notes)
  end
end
