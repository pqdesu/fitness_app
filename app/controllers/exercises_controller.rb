class ExercisesController < ApplicationController
  before_action :require_admin!, except: [:index]
  before_action :set_exercise, only: [:edit, :update, :destroy]

  def index
    @exercises = Exercise.order(:muscle_group, :name)
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

  def set_exercise
    @exercise = Exercise.find(params[:id])
  end

  def exercise_params
    params.require(:exercise).permit(:name, :muscle_group, :equipment)
  end

  def errors_for(record)
    record.errors.full_messages.to_sentence
  end
end
