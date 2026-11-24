# A cardio exercise's rows: incline, speed and time. They are added, corrected and deleted the way
# sets are (WorkoutSetsController), from a planned exercise's page or a logged workout's page.
class CardioEntriesController < ApplicationController
  include LoggingDate

  # From an exercise of a workout day the row goes into that workout's session of the page's date,
  # created with its first row (WorkoutExercise#entry_on!); from a logged workout, into that entry.
  def create
    cardio_entry = nil
    back = nil

    CardioEntry.transaction do
      if params[:workout_exercise_id]
        planned = current_user.workout_exercises.find(params[:workout_exercise_id])
        date = logging_date(planned.workout_day)
        back = workout_exercise_path(planned, date:)
        entry = planned.entry_on!(date)
      else
        entry = current_user.workout_log_exercises.find(params[:workout_log_exercise_id])
        back = workout_log_path(entry.workout_log_id, anchor: "entry-#{entry.id}")
      end

      # Adding while the cardio timer runs stops it: the row takes its time unless one was typed.
      entry.update!(rest_ended_at: Time.current) if entry.rest_running?
      cardio_entry = entry.cardio_entries.new(cardio_entry_params)
      cardio_entry.duration_seconds ||= entry.timer_seconds
      # The cardio timer is done once the row has the time.
      entry.take_rest!
      # A row that is not saved must not leave an empty workout behind.
      raise ActiveRecord::Rollback unless cardio_entry.save
    end

    if cardio_entry.persisted?
      redirect_to back, notice: "#{cardio_entry.workout_log_exercise.name} added."
    else
      redirect_to back, alert: "Not added: #{errors_of(cardio_entry)}."
    end
  rescue ActiveRecord::RecordInvalid => e
    # The workout could not be started: the date is still to come, or this split already has
    # another workout logged that day.
    redirect_to back, alert: "Not added: #{errors_of(e.record)}."
  end

  def update
    cardio_entry = current_user.cardio_entries.find(params[:id])
    message = if cardio_entry.update(cardio_entry_params)
      { notice: "#{name_of(cardio_entry)} updated." }
    else
      { alert: "#{name_of(cardio_entry)} not updated: #{errors_of(cardio_entry)}." }
    end
    redirect_to page_of(cardio_entry), status: :see_other, **message
  end

  def destroy
    cardio_entry = current_user.cardio_entries.find(params[:id])
    cardio_entry.destroy
    redirect_to page_of(cardio_entry), notice: "#{name_of(cardio_entry)} deleted.", status: :see_other
  end

  private

  # "Treadmill 2": its exercise and number, as the row's menu names it.
  def name_of(cardio_entry) = "#{cardio_entry.workout_log_exercise.name} #{cardio_entry.entry_number}"

  # The exercise page sends its workout_exercise_id (see cardio_entries/_entry); otherwise it was
  # the logged workout page.
  def page_of(cardio_entry)
    planned = current_user.workout_exercises.find_by(id: params[:workout_exercise_id]) if params[:workout_exercise_id].present?
    return workout_exercise_path(planned, date: text_param(:date).presence) if planned

    entry = cardio_entry.workout_log_exercise
    workout_log_path(entry.workout_log_id, anchor: "entry-#{entry.id}")
  end

  # The time comes as minutes and seconds; both empty is no time, which the row refuses.
  def cardio_entry_params
    fields = params.expect(cardio_entry: [:incline, :speed, :minutes, :seconds])
    time = fields.extract!(:minutes, :seconds)
    duration = (time[:minutes].to_i * 60) + time[:seconds].to_i if time.values.any?(&:present?)
    fields.merge(duration_seconds: duration)
  end
end
