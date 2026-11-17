class User < ApplicationRecord
  # :lockable locks the account for a while after too many wrong passwords (see config/initializers/devise.rb).
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :lockable

  # Declared before the associations, so it runs before anything of the user is deleted.
  before_destroy :keep_an_admin

  has_many :splits, dependent: :destroy
  # The split the user chose to train right now. See #current_split.
  belongs_to :active_split, class_name: "Split", optional: true
  has_many :workout_days, through: :splits
  # Kept when a split is deleted: the history is the user's, not the split's.
  has_many :workout_logs, dependent: :destroy
  # Exercises this user created for themselves (not part of the shared catalogue).
  has_many :exercises, dependent: :destroy
  # Everything below the user's splits and logs, so a controller finds a record through its owner:
  # current_user.workout_sets.find(id).
  has_many :workout_exercises, through: :workout_days
  has_many :workout_log_exercises, through: :workout_logs
  has_many :workout_sets, through: :workout_log_exercises

  validate :active_split_is_own

  # The split the dashboard follows: the one the user marked as active,
  # or their oldest split while they have not chosen one.
  def current_split
    active_split || splits.order(:id).first
  end

  # The only admin left: deleting this account would leave nobody to manage the catalogue and the users.
  def last_admin?
    admin? && !User.where(admin: true).where.not(id:).exists?
  end

  private

  def keep_an_admin
    return unless last_admin?

    errors.add(:base, "You are the only admin. Make someone else an admin first")
    throw :abort
  end

  def active_split_is_own
    return if active_split.nil? || active_split.user_id == id

    errors.add(:active_split, "must be one of your splits")
  end
end
