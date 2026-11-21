class WorkoutSetsController < ApplicationController
  include LoggingDate

  # Adds a set. From an exercise of a workout day it goes into that workout's session of the
  # page's date (see LoggingDate), which is created on the first set; never on a date to come.
  # From a logged workout it goes into that entry.
  def create
    workout_set = nil
    back = nil

    WorkoutSet.transaction do
      if params[:workout_exercise_id]
        planned = current_user.workout_exercises.find(params[:workout_exercise_id])
        date = logging_date(planned.workout_day)
        back = workout_exercise_path(planned, date:)
        # One session per workout per day: this joins that day's log of the workout if there is one.
        # A date to come is refused by WorkoutLog, so nothing is logged ahead of the day.
        entry = planned.entry_on!(date)
      else
        entry = current_user.workout_log_exercises.find(params[:workout_log_exercise_id])
        back = workout_log_path(entry.workout_log_id, anchor: "entry-#{entry.id}")
      end

      workout_set = entry.workout_sets.new(workout_set_params)
      # A set that is not saved must not leave an empty workout behind.
      raise ActiveRecord::Rollback unless workout_set.save
    end

    if workout_set.persisted?
      redirect_to back, notice: "Set #{workout_set.set_number} added."
    else
      redirect_to back, alert: "Set not added: #{errors_of(workout_set)}."
    end
  rescue ActiveRecord::RecordInvalid => e
    # The workout could not be started: the date is still to come, or this split already has
    # another workout logged that day.
    redirect_to back, alert: "Set not added: #{errors_of(e.record)}."
  end

  # Corrects the weight, reps or note of a set that is already recorded.
  def update
    workout_set = current_user.workout_sets.find(params[:id])
    message = if workout_set.update(workout_set_params)
      { notice: "Set #{workout_set.set_number} updated." }
    else
      { alert: "Set not updated: #{errors_of(workout_set)}." }
    end
    redirect_to page_of(workout_set), status: :see_other, **message
  end

  def destroy
    workout_set = current_user.workout_sets.find(params[:id])
    workout_set.destroy
    redirect_to page_of(workout_set), notice: "Set deleted.", status: :see_other
  end

  private

  # Where the set was edited or deleted from. The exercise page says so itself by sending its
  # workout_exercise_id (see workout_sets/_set); otherwise it was the logged workout page.
  def page_of(workout_set)
    planned = current_user.workout_exercises.find_by(id: params[:workout_exercise_id]) if params[:workout_exercise_id].present?
    return workout_exercise_path(planned, date: text_param(:date).presence) if planned

    entry = workout_set.workout_log_exercise
    workout_log_path(entry.workout_log_id, anchor: "entry-#{entry.id}")
  end

  def workout_set_params
    params.expect(workout_set: [:reps_completed, :weight_used, :notes, { set_tag_ids: [] }])
  end
end
