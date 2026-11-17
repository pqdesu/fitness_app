class ExercisesController < ApplicationController
  include ExercisePicker
  include Paginated

  # The form on this page is the admin's: it adds to the shared catalogue, or to the admin's own
  # exercises. Everyone else creates their own exercises from the "Add exercises" modal.
  before_action -> { require_admin!(back: exercises_path, message: "Only an admin can manage the exercise catalogue.") },
                only: [:new, :create]
  before_action :set_exercise, only: [:edit, :update, :destroy]
  before_action :set_return_day, only: [:edit, :update]

  def index
    @exercises = paginate(Exercise.visible_to(current_user).order(:muscle_group, :name, :id), per: 30)
    @usage = WorkoutExercise.where(exercise_id: @exercises.map(&:id)).group(:exercise_id).count
  end

  def new
    @exercise = Exercise.new
    @shared = true
  end

  def create
    @exercise = Exercise.new(exercise_params)
    @shared = shared_exercise_requested?
    @exercise.user = current_user unless @shared

    if @exercise.save
      redirect_to exercises_path, notice: "#{@exercise.name} added to #{@shared ? 'the catalogue' : 'your own exercises'}."
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit
  end

  def update
    if @exercise.update(exercise_params)
      redirect_to (@return_day || exercises_path), notice: "#{@exercise.name} updated."
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    if @exercise.destroy
      redirect_to exercises_path, notice: "#{@exercise.name} deleted.", status: :see_other
    else
      redirect_to exercises_path, alert: "#{@exercise.name} was not deleted: #{errors_of(@exercise)}", status: :see_other
    end
  end

  private

  # Everyone manages the exercises they created; an admin also manages the shared catalogue.
  def set_exercise
    manageable = current_user.admin? ? Exercise.visible_to(current_user) : current_user.exercises
    @exercise = manageable.find(params[:id])
  end

  # The workout day the edit was opened from (an admin renames an exercise there), to go back to.
  def set_return_day
    @return_day = current_user.workout_days.find_by(id: params[:workout_day_id]) if params[:workout_day_id].present?
  end

  def exercise_params
    params.expect(exercise: [:name, :muscle_group])
  end
end
