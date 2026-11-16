# Reads what the "Add exercises" modal sends: either exercises ticked in the catalogue
# (exercise_ids), or a new exercise the user creates on the spot (exercise[name, muscle_group]).
module ExercisePicker
  extend ActiveSupport::Concern

  private

  # Returns [exercises, error message].
  def picked_exercises
    if params[:exercise].present?
      exercise = find_or_build_exercise(params.require(:exercise).permit(:name, :muscle_group))
      exercise.save ? [[exercise], nil] : [[], exercise.errors.full_messages.to_sentence]
    else
      exercises = Exercise.visible_to(current_user).where(id: params[:exercise_ids]).order(:name).to_a
      exercises.any? ? [exercises, nil] : [[], "Choose at least one exercise"]
    end
  end

  # A name the user can already pick is used as it is, so typing "bench press" does not make a
  # twin of the catalogue's Bench press. Otherwise the new exercise is the user's own, unless an
  # admin asked for it to go into the shared catalogue.
  def find_or_build_exercise(attributes)
    name = attributes[:name].to_s.squish
    existing = Exercise.visible_to(current_user).where("LOWER(name) = ?", name.downcase).order(:id).first
    return existing if existing

    Exercise.new(attributes).tap { |exercise| exercise.user = current_user unless shared_exercise_requested? }
  end

  # Only an admin adds to the shared catalogue, and only by ticking "shared".
  def shared_exercise_requested?
    current_user.admin? && ActiveModel::Type::Boolean.new.cast(params.dig(:exercise, :shared)) == true
  end
end
