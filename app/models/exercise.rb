# An exercise users can add to a workout day or a logged workout.
# - Without a user it belongs to the shared catalogue, which only admins manage.
# - With a user it is that user's own exercise, and only they see it.
# - Its equipment (Equipped) is what its planned and logged lifts start with; unilateral marks an
#   exercise done one arm or one leg at a time.
class Exercise < ApplicationRecord
  include Equipped

  # Cardio is not a muscle, but it is chosen like one: a cardio exercise is logged as incline,
  # speed and time instead of weight and reps (CardioEntry).
  MUSCLE_GROUPS = %w[Chest Back Shoulders Biceps Triceps Legs Core Cardio].freeze

  belongs_to :user, optional: true
  # An exercise that is part of someone's program cannot be deleted:
  # destroy returns false and adds an error instead of raising.
  has_many :workout_exercises, dependent: :restrict_with_error
  has_many :workout_days, through: :workout_exercises
  # Logged history keeps its own copy of the name, so it only loses the link.
  has_many :workout_log_exercises, dependent: :nullify

  scope :shared, -> { where(user_id: nil) }
  scope :visible_to, ->(user) { where(user_id: [nil, user.id]) }

  # Tidied when assigned, and when looked up by (find_by(name: " bench  press ") finds "bench press").
  normalizes :name, with: ->(name) { name.squish.presence }
  normalizes :muscle_group, with: lambda(&:presence)

  # No twins in the same list: one of each name in the catalogue, and one among a user's own.
  validates :name, presence: true, length: { maximum: 80 },
                   uniqueness: { scope: :user_id, case_sensitive: false, message: "is already in your exercises" }
  # Chosen from the list, or left empty ("Other").
  validates :muscle_group, inclusion: { in: MUSCLE_GROUPS, message: "must be one of the listed muscle groups" }, allow_nil: true

  after_update :rename_linked_lifts, if: :saved_change_to_name?

  def shared?
    user_id.nil?
  end

  def cardio? = muscle_group == "Cardio"

  # Heading the exercise is listed under when choosing one.
  def group
    muscle_group.presence || "Other"
  end

  private

  # Plans and logs store the name themselves; keep them in step with the exercise.
  def rename_linked_lifts
    workout_exercises.update_all(name:)
    workout_log_exercises.update_all(name:)
  end
end
