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

  def nav_link_to(label, path, active:)
    link_to label, path, class: class_names("nav-link", active: active)
  end
end
