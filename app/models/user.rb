class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :splits, dependent: :destroy
  # The split the user chose to train right now. See #current_split.
  belongs_to :active_split, class_name: "Split", optional: true
  has_many :workout_days, through: :splits
  # Kept when a split is deleted: the history is the user's, not the split's.
  has_many :workout_logs, dependent: :destroy
  # Exercises this user created for themselves (not part of the shared catalogue).
  has_many :exercises, dependent: :destroy

  validate :active_split_is_own

  # The split the dashboard follows: the one the user marked as active,
  # or their oldest split while they have not chosen one.
  def current_split
    active_split || splits.order(:id).first
  end

  private

  def active_split_is_own
    return if active_split.nil? || active_split.user_id == id

    errors.add(:active_split, "must be one of your splits")
  end
end
