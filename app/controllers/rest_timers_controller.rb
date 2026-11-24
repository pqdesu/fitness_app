# The rest timer between sets of a logged exercise: Start rest after a set, Stop before the next,
# and that next set saves the rest (WorkoutSetsController#create). Only the times are saved; the
# page counts in between (timer_controller.js). A cardio exercise uses the same two columns for its
# own timer: Stop fills the Add form with the time, and Add saves it (CardioEntriesController#create).
class RestTimersController < ApplicationController
  include LoggingDate

  def create
    entry.update!(rest_started_at: Time.current, rest_ended_at: nil)
    back
  rescue ActiveRecord::RecordInvalid => e
    # The workout could not be started: the date is still to come, or this split already has
    # another workout logged that day.
    redirect_to workout_exercise_path(params[:workout_exercise_id], date: text_param(:date).presence),
                alert: "Timer not started: #{errors_of(e.record)}."
  end

  def update
    entry.update!(rest_ended_at: Time.current) if entry.rest_running?
    back
  end

  # "No rest": the timer is thrown away and the next set saves none.
  def destroy
    entry.update!(rest_started_at: nil, rest_ended_at: nil)
    back
  end

  private

  # From a planned exercise (a cardio one with nothing logged yet) Start logs the workout on the
  # page's date and the exercise in it, as its first row would (WorkoutExercise#entry_on!).
  def entry
    @entry ||= if params[:workout_log_exercise_id]
      current_user.workout_log_exercises.find(params[:workout_log_exercise_id])
    else
      planned = current_user.workout_exercises.find(params[:workout_exercise_id])
      planned.entry_on!(logging_date(planned.workout_day))
    end
  end

  # Back to the exercise page it was on (it sends workout_exercise_id and date), else the logged workout.
  def back
    planned = current_user.workout_exercises.find_by(id: params[:workout_exercise_id]) if params[:workout_exercise_id].present?
    path = if planned
      workout_exercise_path(planned, date: text_param(:date).presence)
    else
      workout_log_path(entry.workout_log_id, anchor: "entry-#{entry.id}")
    end
    redirect_to path, status: :see_other
  end
end
