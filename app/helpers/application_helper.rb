module ApplicationHelper
  def format_weight(weight)
    return "Bodyweight" if weight.nil?

    "#{number_with_precision(weight, precision: 2, strip_insignificant_zeros: true)} kg"
  end

  # Declares the page a view sits under. The layout draws it as the back button,
  # so every sub-page gets the same control in the same place.
  def back_to(label, path)
    content_for :back, link_to(tag.i(class: "fa-solid fa-arrow-left") + label, path, class: "back-link"), flush: true
  end

  # The weeks (Sunday to Saturday) that cover the month of the given date.
  def month_weeks(date)
    first = date.beginning_of_month.beginning_of_week(:sunday)
    last = date.end_of_month.end_of_week(:sunday)
    (first..last).each_slice(7).to_a
  end

  def nav_link_to(label, path, active:)
    link_to label, path, class: class_names("nav-link", active: active)
  end
end
