class WorkoutDaysController < ApplicationController
  include ExercisePicker
  include LoggingDate

  before_action :set_split, only: [:new, :create]
  before_action :set_workout_day, only: [:show, :edit, :update, :destroy]

  # The workout: first the exercises in that date's session, in its order (planned ones and those
  # added while training; the user drags them into the order done), then the planned ones not
  # started yet, in the plan's order.
  def show
    @workout_exercises = @workout_day.workout_exercises.includes(:exercise)
    @date = logging_date(@workout_day)
    @log = current_user.workout_logs.with_sets.session_of(@workout_day.day, @date)
    planned_of = @log ? @workout_exercises.filter_map { |planned| (entry = planned.entry_in(@log)) && [entry, planned] }.to_h : {}
    # [entry, the planned exercise it is of, or nil when it was added while training]
    @in_workout = @log ? @log.workout_log_exercises.map { |entry| [entry, planned_of[entry]] } : []
    @to_do = @workout_exercises - planned_of.values
    # With the automatic timer on, opening today's workout starts it (and the timer). Not when it
    # could not be logged (the split already has another workout today), so the page never retries.
    @autostart = current_user.timer_auto_start? && @date == Date.current &&
                 (@log || @workout_day.workout_logs.new(date: @date)).valid?
  end

  def new
    # Coming from an empty circle of the week, the weekday is already chosen.
    free = (0..6).to_a - @split.workout_days.pluck(:weekday)
    weekday = text_param(:weekday).presence&.to_i
    @workout_day = @split.workout_days.new(weekday: free.include?(weekday) ? weekday : free.first)
  end

  def create
    @workout_day = @split.workout_days.new(workout_day_params)
    if @workout_day.save
      redirect_to split_path(@split, anchor: "day-#{@workout_day.id}"), notice: "Workout day created. Plan its exercises."
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit
    @split = @workout_day.split
  end

  def update
    if @workout_day.update(workout_day_params)
      redirect_to split_path(@workout_day.split, anchor: "day-#{@workout_day.id}"), notice: "Workout day updated."
    else
      @split = @workout_day.split
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @workout_day.destroy
    redirect_to @workout_day.split, notice: "Workout day deleted.", status: :see_other
  end

  private

  def set_split
    @split = current_user.splits.find(params[:split_id])
  end

  def set_workout_day
    @workout_day = current_user.workout_days.find(params[:id])
  end

  def workout_day_params
    params.expect(workout_day: [:day, :weekday])
  end
end
