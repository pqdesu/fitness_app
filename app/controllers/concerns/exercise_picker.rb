# Reads what the "Add exercises" modal sends: either exercises ticked in the catalogue
# (exercise_ids), or a new exercise the user creates on the spot (exercise[name, muscle_group]).
module ExercisePicker
  extend ActiveSupport::Concern

  private

  # Returns [exercises, error message].
  def picked_exercises
    if params[:exercise].present?
      exercise = Exercise.new(params.require(:exercise).permit(:name, :muscle_group))
      # Only an admin adds to the shared catalogue; everyone else creates an exercise of their own.
      exercise.user = current_user unless current_user.admin?
      exercise.save ? [[exercise], nil] : [[], exercise.errors.full_messages.to_sentence]
    else
      exercises = Exercise.visible_to(current_user).where(id: params[:exercise_ids]).order(:name).to_a
      exercises.any? ? [exercises, nil] : [[], "Choose at least one exercise"]
    end
  end
end
