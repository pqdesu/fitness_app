module ApplicationHelper
  # Gives a sub-page its back button, an arrow the layout draws above the page header. It returns
  # to the page the user was on before (back_controller.js, back_trail.js); `path`, the page this
  # one sits under, is where it goes when there was none, such as a link opened directly.
  def back_to(path)
    content_for :back, link_to(tag.i(class: "fa-solid fa-arrow-left", aria: { hidden: true }), path,
                               class: "back-link", aria: { label: "Back" }, title: "Back",
                               data: { controller: "back", action: "back#go" }), flush: true
  end

  # When a workout was done, by its timer: "6:02 PM ~ 7:15 PM · 1 h 3 min · paused 10 min" (start
  # ~ end, the time recorded and the time paused, both to the second), "Started 6:02 PM" while it runs,
  # nil when the timer was not used. Past midnight each time gets its date as a badge:
  # 11:30 PM [20/11] ~ 1:00 AM [21/11].
  def workout_time(log)
    return if log.started_at.nil?

    paused = "paused #{duration_text(log.paused_seconds)}" if log.paused_seconds.positive?
    return time_parts(["Started #{clock_time(log.started_at)}", paused]) if log.timer_running?

    ended = log.timer_end
    next_day = ended.to_date != log.started_at.to_date
    start = safe_join([clock_time(log.started_at), (day_badge(log.started_at) if next_day)].compact, " ")
    finish = safe_join(["~", clock_time(ended), (day_badge(ended) if next_day)].compact, " ")
    time_parts([start, finish, tag.strong(duration_text(log.recorded_seconds), class: "time-length"), paused],
               dot_after_first: false)
  end

  # The parts of a time line, each kept whole on its line with the "·" that follows it, so a
  # wrapped line never starts with a separator. The first part of a range ("6:02 PM" before
  # "~ 7:15 PM") takes no dot.
  def time_parts(parts, dot_after_first: true)
    parts = parts.compact
    safe_join(parts.each_with_index.map do |part, index|
      dot = index < parts.size - 1 && (index.positive? || dot_after_first)
      tag.span(dot ? safe_join([part, " ·"]) : part, class: "time-part")
    end, " ")
  end

  # A length of time exactly, to the second, never rounded: "45 min", "1 h 3 min 10 s", "20 s".
  def duration_text(seconds)
    hours, rest = seconds.divmod(3600)
    minutes, secs = rest.divmod(60)
    [[hours, "h"], [minutes, "min"], [secs, "s"]].select { |value, _| value.positive? }
                                                 .map { |value, unit| "#{value} #{unit}" }.join(" ").presence || "0 s"
  end

  # The rest before a set: to the second when measured, "~3 min" when typed in whole minutes.
  def rest_text(set)
    set.rest_approx ? "~#{set.rest_seconds / 60} min" : duration_text(set.rest_seconds)
  end

  # Seconds as a clock reads them: 0:42:13. The same as timer_controller.js shows while it runs.
  def clock_duration(seconds)
    format("%<h>d:%<m>02d:%<s>02d", h: seconds / 3600, m: seconds / 60 % 60, s: seconds % 60)
  end

  def clock_time(time)
    l(time, format: "%-l:%M %p")
  end

  def day_badge(time)
    tag.span(l(time, format: "%d/%m"), class: "chip chip-day")
  end

  # Where a day of the dashboard leads: the workout logged on it, or that day's list in History
  # when there were several.
  def day_logs_path(logs, date)
    logs.one? ? workout_log_path(logs.first, from: "dashboard") : workout_logs_path(date: date.iso8601, from: "dashboard")
  end

  # The button that opens the "Add exercises" modal (shared/_exercise_picker), the one of that key if given.
  # On a workout's pages it asks first while the timer is paused (workout_logs/_timer_alert).
  def exercise_picker_button(css, key: nil, label: "Add exercise")
    target = ["#exercise-picker", key].compact.join("-")
    tag.button safe_join([tag.i(class: "fa-solid fa-plus"), " #{label}"]),
               type: "button", class: "btn #{css}", data: { bs_toggle: "modal", bs_target: target, alert_when_paused: "add" }
  end

  def nav_link_to(label, path, active:)
    link_to label, path, class: class_names("nav-link", active:)
  end

  # The app's sections: label, path, Font Awesome icon, and whether the current page belongs to it.
  # The top navbar (tablet and desktop) ends with Exercises; the phone's bottom bar has no room for
  # it, so there Exercises is a link on the dashboard and lights the Dashboard tab.
  def nav_sections(phone: false)
    page = controller_name == "pages" && action_name
    sections = [
      ["Today", root_path, "calendar-day", page == "home" || todays_workout_page?],
      ["Dashboard", dashboard_path, "house", page == "dashboard" || (phone && controller_name == "exercises")],
      ["Splits", splits_path, "layer-group",
       controller_name.in?(%w[splits workout_days workout_exercises]) && !todays_workout_page?],
      ["History", workout_logs_path, "clock-rotate-left",
       controller_name.in?(%w[workout_logs workout_log_exercises workout_timers]) && !todays_workout_page?]
    ]
    phone ? sections : sections << ["Exercises", exercises_path, "dumbbell", controller_name == "exercises"]
  end

  # Today's workout belongs to the Today tab, not Splits or History: a workout day or one of its
  # exercises opened on today's date, a workout started today off the split, and today's logged workout.
  def todays_workout_page?
    date =
      case "#{controller_name}##{action_name}"
      when "workout_days#show", "workout_exercises#show" then @date
      when "workout_logs#new" then Date.current
      when "workout_logs#show" then @workout_log.date
      end
    date == Date.current
  end

  # The short name of the page a signed-in user is on, shown in the top bar on a phone. A
  # "controller#action" key wins over the controller's own.
  PAGE_TITLES = {
    "pages#home" => "Today", "pages" => "Dashboard", "splits#index" => "Splits", "splits" => "Split",
    "workout_days#show" => "Workout", "workout_days" => "Workout day", "workout_exercises" => "Exercise",
    "workout_logs#index" => "History", "workout_logs" => "Workout", "workout_log_exercises" => "Exercise",
    "workout_timers" => "Timer", "exercises#index" => "Exercises", "exercises" => "Exercise",
    "admin/users" => "Users", "users/registrations" => "Account"
  }.freeze

  def page_title
    PAGE_TITLES["#{controller_path}##{action_name}"] || PAGE_TITLES[controller_path]
  end
end
