# What the dashboard shows for one user on one day (plain Ruby). The home page reads everything
# from here: the active split and this week as it is trained, today's workout with today's and
# last time's sessions, the month calendar, the weekly overview and the recent workouts.
# Each question is asked of the database once, the first time the page needs it.
class Dashboard
  attr_reader :user, :today

  def initialize(user, today)
    @user = user
    @today = today
  end

  def split
    return @split if defined?(@split)

    @split = user.current_split
  end

  def several_splits?
    user.splits.count > 1
  end

  # The split's workout days, in the order of the week.
  def days
    @days ||= split ? split.workout_days.order(:weekday, :id).to_a : []
  end

  # This week as it is trained: the plan, with the workouts moved for this week on their new days.
  def week_plan
    @week_plan ||= split ? split.week_plan(today) : {}
  end

  def week_moved?
    split.present? && split.undoable_week_moves(today).any?
  end

  def today_workout
    week_plan[today.wday]
  end

  # Today's session of today's workout. Sessions are looked up by workout, not by split, so
  # changing or deleting a split keeps today's sets and the "last time" comparison.
  def today_log
    return @today_log if defined?(@today_log)

    @today_log = today_workout && sessions_of_today_workout.session_of(today_workout.day, today)
  end

  # The session before today of today's workout.
  def last_log
    return @last_log if defined?(@last_log)

    @last_log = today_workout && sessions_of_today_workout.of_workout(today_workout.day).where(date: ...today)
                                                          .order(date: :desc, id: :desc).first
  end

  def today_summary
    @today_summary ||= WorkoutSummary.new(today_log)
  end

  # Today's exercises that have sets or cardio rows: the Today box shows them once there are any.
  def today_lifts
    today_log ? today_log.workout_log_exercises.select { |lift| lift.workout_sets.any? || lift.cardio_entries.any? } : []
  end

  # The weeks (Sunday to Saturday) that cover this month.
  def calendar_weeks
    @calendar_weeks ||= (today.beginning_of_month.beginning_of_week(:sunday)..today.end_of_month.end_of_week(:sunday))
                        .each_slice(7).to_a
  end

  # The calendar marks the days a workout was logged on: date => workout logs.
  def calendar_logs
    @calendar_logs ||= user.workout_logs.where(date: calendar_weeks.first.first..calendar_weeks.last.last)
                           .includes(:workout_log_exercises).order(:id).group_by(&:date)
  end

  # Answers how each day stands and which workout day the plan has on it.
  def day_states = @day_states ||= DayStates.new(user, split, today)

  # How each day of the calendar stands, by date (see day_states).
  def calendar_states = @calendar_states ||= day_states.of(calendar_weeks.flatten, calendar_logs)

  # The same for this week, by weekday (0 = Sunday).
  def week_states = @week_states ||= day_states.of(week_dates, week_logs).transform_keys(&:wday)

  # This month's workout logs, with their exercises and sets, oldest first.
  def month_logs
    @month_logs ||= user.workout_logs.where(date: today.all_month).with_sets.includes(workout_day: :split)
                        .order(:date, :id).to_a
  end

  def month_summary
    @month_summary ||= WorkoutSummary.new(month_logs)
  end

  # split => its summary of the month, the busiest first; nil is the workouts outside any split
  # (a deleted split, or a workout trained as an extra).
  def month_by_split
    month_logs.group_by { |log| log.workout_day&.split }
              .transform_values { |logs| WorkoutSummary.new(logs) }
              .sort_by { |_split, summary| -summary.workouts }
  end

  # This week, Sunday to Saturday.
  def week_dates
    @week_dates ||= today.all_week(:sunday).to_a
  end

  # date => this week's workout logs, with their exercises and sets.
  def week_logs
    @week_logs ||= user.workout_logs.where(date: today.all_week(:sunday)).with_sets.order(:id).group_by(&:date)
  end

  def week_summary
    @week_summary ||= WorkoutSummary.new(week_logs.values.flatten)
  end

  # weekday this week => workout day, for the workouts not trained yet: a workout already
  # trained this week has nothing left to move.
  def movable_days
    @movable_days ||= begin
      logged_day_ids = week_logs.values.flatten.filter_map(&:workout_day_id)
      week_plan.reject { |_weekday, day| logged_day_ids.include?(day.id) }
    end
  end

  # workout day id => how many exercises it plans.
  def exercise_counts
    @exercise_counts ||= WorkoutExercise.where(workout_day_id: days.map(&:id)).group(:workout_day_id).count
  end

  # On a rest day: the fixed workouts the split does not have, for a workout outside the split.
  def other_workouts
    WorkoutDay::NAMES - days.flat_map { |day| WorkoutDay.names_for(day.day) }
  end

  # On a rest day: workout name => { weekday this week => workout day }, one pop-up per name.
  def rest_day_choices
    week_plan.group_by { |_weekday, day| day.day }.transform_values(&:to_h)
  end

  def recent_logs
    @recent_logs ||= user.workout_logs.with_sets.includes(workout_day: :split)
                         .order(date: :desc, id: :desc).limit(5).to_a
  end

  # All-time totals. No box shows them at the moment; the owner asked to keep them for later.
  # They are only counted when a page asks.
  def logs_count
    user.workout_logs.count
  end

  def sets_count
    user.workout_sets.count
  end

  private

  def sessions_of_today_workout
    user.workout_logs.with_sets.includes(workout_day: :split)
  end
end
