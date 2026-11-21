class WorkoutLogExercisesController < ApplicationController
  include ExercisePicker
  include LoggingDate

  before_action :set_entry, only: [:edit, :update, :destroy]

  # Adds to a workout: an exercise planned for the day (workout_exercise_id), or the exercises
  # chosen (or the one created) in the "Add exercises" modal. From a workout day's page
  # (workout_day_id) they go into that day's session on the page's date, which starts the
  # session if it has not started yet; the day's plan is not changed.
  def create
    if params[:workout_day_id]
      workout_day = current_user.workout_days.find(params[:workout_day_id])
      date = logging_date(workout_day)
      back = workout_day_path(workout_day, date:)
      workout_log = workout_day.log_on(date) || workout_day.workout_logs.new(date:)
    else
      workout_log = current_user.workout_logs.find(params[:workout_log_id])
    end
    back ||= workout_log_path(workout_log)

    if params[:workout_exercise_id].present?
      entries = [workout_log.workout_log_exercises.new(workout_exercise_id: params[:workout_exercise_id])]
    else
      exercises, error = picked_exercises
      return redirect_to(back, alert: "Nothing added: #{error}.") if error

      entries = exercises.map { |exercise| workout_log.workout_log_exercises.new(exercise:) }
    end

    # A new session is saved with its entries, as they were built on it.
    WorkoutLogExercise.transaction { workout_log.new_record? ? workout_log.save! : entries.each(&:save!) }
    redirect_to(workout_day ? back : workout_log_path(workout_log, anchor: "entry-#{entries.first.id}"),
                notice: "#{entries.map(&:name).to_sentence} added to this workout.")
  rescue ActiveRecord::RecordInvalid => e
    redirect_to back, alert: "Nothing added: #{errors_of(e.record)}."
  end

  def edit
  end

  # Changes the equipment used for this exercise in this workout, and its note. The note is also
  # written on the exercise's page, which sends its workout_exercise_id and date to return there.
  def update
    planned = current_user.workout_exercises.find_by(id: params[:workout_exercise_id]) if params[:workout_exercise_id].present?
    if planned
      saved = @entry.update(entry_params)
      redirect_to workout_exercise_path(planned, date: text_param(:date).presence),
                  **(saved ? { notice: "Note saved." } : { alert: "Note not saved: #{errors_of(@entry)}." })
    elsif @entry.update(entry_params)
      redirect_to workout_log_path(@entry.workout_log_id, anchor: "entry-#{@entry.id}"), notice: "#{@entry.name} updated."
    else
      render :edit, status: :unprocessable_content
    end
  end

  # Takes an exercise out of a workout. One planned for the day stays on the plan (and is offered
  # again); one added while training is simply gone. From a workout day's page it returns there.
  def destroy
    @entry.destroy
    workout_day = current_user.workout_days.find_by(id: params[:workout_day_id]) if params[:workout_day_id].present?
    back = workout_day ? workout_day_path(workout_day, date: text_param(:date).presence) : workout_log_path(@entry.workout_log_id)
    redirect_to back, notice: "#{@entry.name} removed from this workout.", status: :see_other
  end

  private

  def set_entry
    @entry = current_user.workout_log_exercises.find(params[:id])
  end

  def entry_params
    params.expect(workout_log_exercise: [*Equipped::ATTRIBUTES, :notes])
  end
end
