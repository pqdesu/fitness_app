class WorkoutLogExercisesController < ApplicationController
  include ExercisePicker

  before_action :set_entry, only: [:edit, :update, :destroy]

  # Adds to a logged workout: an exercise planned for the day (workout_exercise_id),
  # or the exercises chosen (or the one created) in the "Add exercises" modal.
  def create
    workout_log = current_user.workout_logs.find(params[:workout_log_id])

    if params[:workout_exercise_id].present?
      entries = [workout_log.workout_log_exercises.new(workout_exercise_id: params[:workout_exercise_id])]
    else
      exercises, error = picked_exercises
      return redirect_to(workout_log_path(workout_log), alert: "Nothing added: #{error}.") if error

      entries = exercises.map { |exercise| workout_log.workout_log_exercises.new(exercise:) }
    end

    WorkoutLogExercise.transaction { entries.each(&:save!) }
    redirect_to workout_log_path(workout_log, anchor: "entry-#{entries.first.id}"),
                notice: "#{entries.map(&:name).to_sentence} added to this workout."
  rescue ActiveRecord::RecordInvalid => e
    redirect_to workout_log_path(workout_log), alert: "Nothing added: #{errors_of(e.record)}."
  end

  def edit
  end

  # Changes the equipment used for this exercise in this workout, and its note.
  def update
    if @entry.update(entry_params)
      redirect_to workout_log_path(@entry.workout_log_id, anchor: "entry-#{@entry.id}"), notice: "#{@entry.name} updated."
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @entry.destroy
    redirect_to workout_log_path(@entry.workout_log_id), notice: "Exercise removed from this workout.", status: :see_other
  end

  private

  def set_entry
    @entry = current_user.workout_log_exercises.find(params[:id])
  end

  def entry_params
    params.expect(workout_log_exercise: [:equipment, :machine_brand, :notes])
  end
end
