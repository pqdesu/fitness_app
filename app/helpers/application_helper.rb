module ApplicationHelper
  def format_weight(weight)
    return "Bodyweight" if weight.nil?

    "#{number_with_precision(weight, precision: 2, strip_insignificant_zeros: true)} kg"
  end

  def nav_link_to(label, path, active:)
    link_to label, path, class: class_names("nav-link", active: active)
  end
end
