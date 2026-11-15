class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :splits, dependent: :destroy
  has_many :workout_days, through: :splits
  has_many :workout_logs, through: :workout_days
  # Exercises this user created for themselves (not part of the shared catalogue).
  has_many :exercises, dependent: :destroy
end
