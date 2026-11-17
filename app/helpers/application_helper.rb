module ApplicationHelper
  def format_weight(weight)
    return "Bodyweight" if weight.nil?

    "#{weight_number(weight)} kg"
  end

  # A weight as typed: up to three decimals, without trailing zeros (80, 32.5, 1.125).
  def weight_number(weight)
    number_with_precision(weight, precision: 3, strip_insignificant_zeros: true)
  end

  # Declares the page a view sits under. The layout draws it as the back button,
  # so every sub-page gets the same control in the same place.
  def back_to(label, path)
    content_for :back, link_to(tag.i(class: "fa-solid fa-arrow-left") + label, path, class: "back-link"), flush: true
  end

  # A set in one line: "80 kg × 8 reps".
  def weight_and_reps(set)
    "#{format_weight(set.weight_used)} × #{pluralize(set.reps_completed, 'rep')}"
  end

  # Where a day of the dashboard leads: the workout logged on it, or that day's list in History
  # when there were several.
  def day_logs_path(logs, date)
    logs.one? ? workout_log_path(logs.first, from: "dashboard") : workout_logs_path(date: date.iso8601, from: "dashboard")
  end

  # The button that opens the "Add exercises" modal (shared/_exercise_picker).
  def exercise_picker_button(css)
    tag.button safe_join([tag.i(class: "fa-solid fa-plus"), " Add exercise"]),
               type: "button", class: "btn #{css}", data: { bs_toggle: "modal", bs_target: "#exercise-picker" }
  end

  def nav_link_to(label, path, active:)
    link_to label, path, class: class_names("nav-link", active:)
  end
end
