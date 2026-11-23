# The rest timer between sets of a logged exercise: Start rest after a set, Stop before the next,
# and that next set saves the rest (WorkoutSetsController#create). Only the times are saved; the
# page counts in between (timer_controller.js).
class RestTimersController < ApplicationController
  def create
    entry.update!(rest_started_at: Time.current, rest_ended_at: nil)
    back
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

  def entry
    @entry ||= current_user.workout_log_exercises.find(params[:workout_log_exercise_id])
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
