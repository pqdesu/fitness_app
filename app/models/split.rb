class Split < ApplicationRecord
  belongs_to :user
  has_many :workout_days, dependent: :destroy

  validates :name, presence: true
end
