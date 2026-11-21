module ApplicationHelper
  def format_weight(weight)
    return "Bodyweight" if weight.nil?

    "#{weight_number(weight)} kg"
  end

  # A weight as typed: up to three decimals, without trailing zeros (80, 32.5, 1.125).
  def weight_number(weight)
    number_with_precision(weight, precision: 3, strip_insignificant_zeros: true)
  end

  # Gives a sub-page its back button, an arrow the layout draws above the page header. It returns
  # to the page the user was on before (back_controller.js, back_trail.js); `path`, the page this
  # one sits under, is where it goes when there was none, such as a link opened directly.
  def back_to(path)
    content_for :back, link_to(tag.i(class: "fa-solid fa-arrow-left", aria: { hidden: true }), path,
                               class: "back-link", aria: { label: "Back" }, title: "Back",
                               data: { controller: "back", action: "back#go" }), flush: true
  end

  # A set in one line: "80 kg × 8 reps".
  def weight_and_reps(set)
    "#{format_weight(set.weight_used)} × #{pluralize(set.reps_completed, 'rep')}"
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
end
