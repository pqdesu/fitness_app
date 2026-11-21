# A tag on a set (SetTag on WorkoutSet).
class WorkoutSetTag < ApplicationRecord
  belongs_to :workout_set
  belongs_to :set_tag
end
