class WorkoutExercisesController < ApplicationController
  include ExercisePicker
  include LoggingDate

  before_action :set_workout_exercise, only: [:show, :update, :move, :destroy]

  # Opening an exercise: the sets of the date its workout is logged on (see LoggingDate), and the
  # form to add the next one, unless that date is still to come.
  def show
    @workout_day = @workout_exercise.workout_day
    @date = logging_date(@workout_day)
    @entry = @workout_exercise.entry_on(@date)
    @sets = @entry ? @entry.workout_sets.includes(:set_tags).order(:set_number).to_a : []
    # That date's session, for its paused-timer alert, even before this exercise has a set.
    @log = @entry&.workout_log || @workout_day.log_on(@date)
    # Pre-fills the form, so repeating the last set is a single tap.
    @last_set = @sets.last || WorkoutSet.where(workout_log_exercise: @workout_exercise.workout_log_exercises)
                                        .order(created_at: :desc, id: :desc).first
  end

  # Plans the exercises chosen (or the one created) in a day's "Plan exercises" modal on the split
  # page. Only the plan changes here: exercises added while training go into the workout instead
  # (WorkoutLogExercisesController#create).
  def create
    workout_day = current_user.workout_days.find(params[:workout_day_id])
    back = plan_path(workout_day)
    exercises, error = picked_exercises

    # An exercise is on a day once: the ones already there are left out.
    on_day = workout_day.workout_exercises.where(exercise_id: exercises.filter_map(&:id)).pluck(:exercise_id) unless error
    if error
      redirect_to back, alert: "Nothing added: #{error}."
    elsif (exercises = exercises.reject { |exercise| on_day.include?(exercise.id) }).empty?
      redirect_to back, alert: "Nothing added: already on this day."
    else
      WorkoutExercise.transaction { exercises.each { |exercise| workout_day.workout_exercises.create!(exercise:) } }
      redirect_to back, notice: "#{exercises.map(&:name).to_sentence} planned for #{workout_day.day}."
    end
  end

  # Changes the equipment used for this exercise. Sets already recorded on the page's date were
  # done on the equipment being chosen now, so that entry follows; other workouts keep theirs.
  def update
    date = logging_date(@workout_exercise.workout_day)
    if @workout_exercise.update(equipment_params)
      @workout_exercise.entry_on(date)&.update(equipment_params)
      redirect_to workout_exercise_path(@workout_exercise, date:), notice: "Equipment saved."
    else
      redirect_to workout_exercise_path(@workout_exercise, date:), alert: "Equipment not saved: #{errors_of(@workout_exercise)}."
    end
  end

  # Moves an exercise to where it was dropped in the day's plan (split page); the workout day follows it.
  def move
    @workout_exercise.move!(params[:to])
    flash[:moved] = @workout_exercise.id # lights the row up on the page (.just-moved)
    redirect_to plan_path(@workout_exercise.workout_day), status: :see_other
  end

  # Takes an exercise off the plan (from the split page). Workouts already logged keep it.
  def destroy
    @workout_exercise.destroy
    redirect_to plan_path(@workout_exercise.workout_day),
                notice: "#{@workout_exercise.name} removed from #{@workout_exercise.workout_day.day}.", status: :see_other
  end

  private

  def plan_path(workout_day)
    split_path(workout_day.split, anchor: "day-#{workout_day.id}")
  end

  def set_workout_exercise
    @workout_exercise = current_user.workout_exercises.find(params[:id])
  end

  def equipment_params
    params.expect(workout_exercise: Equipped::ATTRIBUTES)
  end
end
