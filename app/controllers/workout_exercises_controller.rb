class WorkoutExercisesController < ApplicationController
  include ExercisePicker

  before_action :set_workout_exercise, only: [:show, :update, :destroy]

  # Opening an exercise: today's sets, and the form to add the next one.
  def show
    @workout_day = @workout_exercise.workout_day
    @entry = @workout_exercise.workout_log_exercises.joins(:workout_log)
                              .where(workout_logs: { date: Date.current }).order(:id).first
    @sets = @entry ? @entry.workout_sets.order(:set_number).to_a : []
    # Pre-fills the form, so repeating the last set is a single tap.
    @last_set = @sets.last || WorkoutSet.joins(:workout_log_exercise)
                                        .where(workout_log_exercises: { workout_exercise_id: @workout_exercise.id })
                                        .order(created_at: :desc, id: :desc).first
  end

  # Adds the exercises chosen (or the one created) in the "Add exercises" modal to the day.
  def create
    workout_day = current_user.workout_days.find(params[:workout_day_id])
    exercises, error = picked_exercises

    if error
      redirect_to workout_day, alert: "Nothing added: #{error}."
    else
      WorkoutExercise.transaction do
        exercises.each { |exercise| workout_day.workout_exercises.create!(exercise: exercise) }
      end
      redirect_to workout_day, notice: "#{exercises.map(&:name).to_sentence} added."
    end
  end

  # Changes the equipment used for this exercise.
  def update
    if @workout_exercise.update(equipment_params)
      redirect_to @workout_exercise, notice: "Equipment saved."
    else
      redirect_to @workout_exercise, alert: "Equipment not saved: #{@workout_exercise.errors.full_messages.to_sentence}."
    end
  end

  def destroy
    @workout_exercise.destroy
    redirect_to @workout_exercise.workout_day, notice: "#{@workout_exercise.name} removed from this day.", status: :see_other
  end

  private

  def set_workout_exercise
    @workout_exercise = WorkoutExercise.joins(workout_day: :split)
                                       .where(splits: { user_id: current_user.id })
                                       .find(params[:id])
  end

  def equipment_params
    params.require(:workout_exercise).permit(:equipment, :machine_brand)
  end
end
