# Reads what the "Add exercises" modal sends: either exercises ticked in the catalogue
# (exercise_ids), or a new exercise the user creates on the spot (exercise[name, muscle_group,
# unilateral and the equipment its lifts start with]).
module ExercisePicker
  extend ActiveSupport::Concern

  included do
    helper_method :picker_exercises
  end

  private

  # What the modal lists: the catalogue and the user's own exercises.
  def picker_exercises
    @picker_exercises ||= picker_scope.order(:name).to_a
  end

  # What can be picked: in a Cardio workout (cardio_workout?) only cardio exercises, so ones posted
  # from elsewhere are left out too.
  def picker_scope
    scope = Exercise.visible_to(current_user)
    cardio_workout? ? scope.where(muscle_group: "Cardio") : scope
  end

  # A controller whose workout is today's Cardio workout says so (WorkoutLog::CARDIO).
  def cardio_workout? = false

  # Returns [exercises, error message]. A new exercise is returned unsaved: it is saved with the
  # row it is added to (the caller's create!), so it does not stay behind when the add fails.
  def picked_exercises
    if params[:exercise].present?
      attributes = params.expect(exercise: [:name, :muscle_group, :unilateral, *Equipped::ATTRIBUTES])
      # One created in a Cardio workout is cardio, whatever was sent.
      attributes[:muscle_group] = "Cardio" if cardio_workout?
      exercise = find_or_build_exercise(attributes)
      exercise.valid? ? [[exercise], nil] : [[], errors_of(exercise)]
    else
      exercises = picker_scope.where(id: params[:exercise_ids]).order(:name).to_a
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
