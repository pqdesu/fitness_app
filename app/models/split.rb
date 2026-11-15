class Split < ApplicationRecord
  belongs_to :user
  has_many :workout_days, dependent: :destroy

  validates :name, presence: true

  def active?
    user.current_split == self
  end
end
