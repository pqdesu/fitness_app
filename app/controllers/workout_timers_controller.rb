# The workout timer: Start, then Pause and Resume, then Stop. Each saves one time (started_at,
# paused_at, ended_at) or adds the pause just ended to paused_seconds; nothing is saved while it
# runs. Only today's workout starts; once started it pauses, resumes and stops whenever, past
# midnight too. A stopped timer is done. From a workout day's page with nothing logged yet,
# Start logs the workout (with no exercises). With the automatic timer on, the page presses Start
# itself when it opens (auto_submit_controller.js). edit and update correct the finish from History.
class WorkoutTimersController < ApplicationController
  include LoggingDate

  # Start, or Resume a paused timer.
  def create
    log = workout_log
    return back_to_workout(log, alert: "This timer was stopped.") if log.ended_at
    # A new timer starts on today's workout only; a paused one resumes whenever.
    return back_to_workout(log, alert: "The timer only starts on today's workout.") unless log.timer_today? || log.timer_paused?
    # Already running (a second tap, or a page opened again): nothing changes.
    return back_to_workout(log) if log.timer_running?

    resuming = log.timer_paused?
    if resuming
      log.resume_timer
    else
      log.started_at = Time.current
    end
    if log.save
      back_to_workout log, notice: resuming ? "Timer resumed." : "Timer started."
    else
      back_to_workout log, alert: "Timer not started: #{errors_of(log)}."
    end
  end

  def pause
    log = current_user.workout_logs.find(params[:workout_log_id])
    return back_to_workout(log, alert: "This timer is not running.") unless log.timer_running?

    log.pause_timer
    log.save!
    back_to_workout log, notice: "Timer paused."
  end

  def destroy
    log = current_user.workout_logs.find(params[:workout_log_id])
    return back_to_workout(log, alert: "This timer is not running.") unless log.timer_running? || log.timer_paused?

    log.stop_timer
    log.save!
    back_to_workout log, notice: "Timer stopped."
  end

  # From History: corrects when the workout finished, for a timer left running too long.
  def edit
    @workout_log = current_user.workout_logs.find(params[:workout_log_id])
    redirect_to workout_logs_path, alert: "This workout has no timer." unless @workout_log.started_at
  end

  def update
    @workout_log = current_user.workout_logs.find(params[:workout_log_id])
    return redirect_to(workout_logs_path, alert: "This workout has no timer.") unless @workout_log.started_at

    if @workout_log.finish_at(params.expect(:finished_at)) && @workout_log.save
      finished = helpers.clock_time(@workout_log.ended_at)
      redirect_to workout_logs_path, notice: "Timer saved: #{@workout_log.workout} finished at #{finished}."
    else
      @workout_log.errors.add(:base, "Choose the time it finished") if @workout_log.errors.empty?
      render :edit, status: :unprocessable_content
    end
  end

  private

  def workout_log
    return current_user.workout_logs.find(params[:workout_log_id]) if params[:workout_log_id]

    workout_day = current_user.workout_days.find(params[:workout_day_id])
    date = logging_date(workout_day)
    workout_day.log_on(date) || workout_day.workout_logs.new(date:)
  end

  # Back to the page the button was on; a workout not saved yet falls back to the dashboard.
  def back_to_workout(log, **flash)
    redirect_back_or_to (log.persisted? ? workout_log_path(log) : root_path), status: :see_other, **flash
  end
end
