# An exercise users can add to a workout day or a logged workout.
# - Without a user it belongs to the shared catalogue, which only admins manage.
# - With a user it is that user's own exercise, and only they see it.
class Exercise < ApplicationRecord
  MUSCLE_GROUPS = %w[Chest Back Shoulders Biceps Triceps Legs Calves Core].freeze

  belongs_to :user, optional: true
  # An exercise that is part of someone's program cannot be deleted:
  # destroy returns false and adds an error instead of raising.
  has_many :workout_exercises, dependent: :restrict_with_error
  has_many :workout_days, through: :workout_exercises
  # Logged history keeps its own copy of the name, so it only loses the link.
  has_many :workout_log_exercises, dependent: :nullify

  scope :shared, -> { where(user_id: nil) }
  scope :visible_to, ->(user) { where(user_id: [nil, user.id]) }

  validates :name, presence: true

  after_update :rename_linked_lifts, if: :saved_change_to_name?

  def shared?
    user_id.nil?
  end

  # Heading the exercise is listed under when choosing one.
  def group
    muscle_group.presence || "Other"
  end

  private

  # Plans and logs store the name themselves; keep them in step with the exercise.
  def rename_linked_lifts
    workout_exercises.update_all(name: name)
    workout_log_exercises.update_all(name: name)
  end
end
