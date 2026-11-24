module CalendarHelper
  # The tooltip and spoken label of a day of the calendar: its date, and what it holds. A missed
  # day says it can be added; workout_day is the plan's workout on a planned or missed day.
  def day_title(date, state, logs, workout_day)
    label = l(date, format: "%A, %B %-d")
    what = day_what(state, logs, workout_day)
    what ? "#{label}: #{what}" : label
  end

  private

  def day_what(state, logs, workout_day)
    if logs.any?(&:logged?) then "#{logs.map(&:workout).to_sentence} #{'workout'.pluralize(logs.size)}"
    elsif state == :missed then "#{workout_day.day} missed. Add it."
    elsif state == :planned then "#{workout_day.day} planned"
    end
  end
end
