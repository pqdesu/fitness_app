# A workout day trained on another weekday for one week: "this week Lower is on Tuesday, not on
# Wednesday". It belongs to that one week (week_start is its Sunday) and leaves the split's plan
# as it is, so the next week is back to the plan. Read through Split#week_plan and written
# through Split#move_for_week!.
class WorkoutDayMove < ApplicationRecord
  belongs_to :workout_day

  validates :week_start, presence: true, uniqueness: { scope: :workout_day_id }
  validates :weekday, inclusion: { in: 0..6 }

  def self.week_start_of(date)
    date.beginning_of_week(:sunday)
  end
end
