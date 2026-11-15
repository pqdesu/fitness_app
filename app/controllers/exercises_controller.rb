class ExercisesController < ApplicationController
  # Only an admin adds to the shared catalogue here.
  # Users create their own exercises from the "Add exercises" modal.
  before_action :require_admin!, only: [:new, :create]
  before_action :set_exercise, only: [:edit, :update, :destroy]

  def index
    @exercises = Exercise.visible_to(current_user).order(:muscle_group, :name)
    @usage = WorkoutExercise.group(:exercise_id).count
  end

  def new
    @exercise = Exercise.new
  end

  def create
    @exercise = Exercise.new(exercise_params)
    if @exercise.save
      redirect_to exercises_path, notice: "#{@exercise.name} added to the catalogue."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @exercise.update(exercise_params)
      redirect_to exercises_path, notice: "#{@exercise.name} updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @exercise.destroy
      redirect_to exercises_path, notice: "#{@exercise.name} deleted.", status: :see_other
    else
      redirect_to exercises_path, alert: "#{@exercise.name} was not deleted: #{errors_for(@exercise)}", status: :see_other
    end
  end

  private

  # An admin manages the shared catalogue; everyone else manages only the exercises they created.
  def set_exercise
    manageable = current_user.admin? ? Exercise.shared : current_user.exercises
    @exercise = manageable.find(params[:id])
  end

  def exercise_params
    params.require(:exercise).permit(:name, :muscle_group)
  end

  def errors_for(record)
    record.errors.full_messages.to_sentence
  end
end
