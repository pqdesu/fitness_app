# The date a workout day's sets are logged on. A workout day's pages pass it along in ?date= (the
# dashboard's "Start workout" and "Train as extra" say today); a page opened without one logs on
# the day this workout falls on this week. So Wednesday's workout opened on Thursday fills in
# Wednesday, a workout later this week takes no sets yet, and a workout started before midnight
# stays on the day it was started.
module LoggingDate
  extend ActiveSupport::Concern

  included do
    helper_method :logging_date_label
  end

  private

  def logging_date(workout_day)
    date = text_param(:date)
    (Date.iso8601(date) if date.present?) || workout_day.date_in_week_of(Date.current)
  rescue Date::Error
    workout_day.date_in_week_of(Date.current)
  end

  # "Today" or the weekday, for the headings of the pages that log on a date.
  def logging_date_label(date)
    date == Date.current ? "Today" : I18n.l(date, format: "%A")
  end
end
