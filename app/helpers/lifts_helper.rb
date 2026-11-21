# How a lift's sets and equipment are written and offered: weights ("80 kg", "Bodyweight + 10 kg"),
# a set in one line, and the admin's equipment names and set tags for the forms.
module LiftsHelper
  # "80 kg", or "Bodyweight" for a set without a weight. On a bodyweight exercise (bodyweight: true)
  # the weight is added or taken off: "Bodyweight + 10 kg", "Bodyweight − 10 kg", with "BW" in place
  # of "Bodyweight" on a phone; plain: true gives the long text alone, for a sentence (a confirm).
  def format_weight(weight, bodyweight: false, plain: false)
    return "Bodyweight" if weight.nil? && !bodyweight
    return "#{weight_number(weight)} kg" unless bodyweight

    word = plain ? "Bodyweight" : bodyweight_word
    return word if weight.nil? || weight.zero?

    safe_join([word, " #{weight.negative? ? '−' : '+'} #{weight_number(weight.abs)} kg"])
  end

  # "Bodyweight", or "BW" on a phone, where the set table has little room.
  def bodyweight_word
    safe_join([tag.span("Bodyweight", class: "d-none d-sm-inline"), tag.span("BW", class: "d-sm-none")])
  end

  # A weight as typed: up to three decimals, without trailing zeros (80, 32.5, 1.125).
  def weight_number(weight)
    number_with_precision(weight, precision: 3, strip_insignificant_zeros: true)
  end

  # A set in one line: "80 kg × 8 reps", "Bodyweight + 10 kg × 8 reps".
  def weight_and_reps(set, plain: false)
    safe_join([format_weight(set.weight_used, bodyweight: set.bodyweight?, plain:), " × #{pluralize(set.reps_completed, 'rep')}"])
  end

  # The names of a kind of equipment in the admin's catalogue, read once per page (a split page
  # has an "Add exercises" form per day).
  def equipment_names(kind)
    (@equipment_names ||= EquipmentItem.order(:name).pluck(:kind, :name).group_by(&:first)).fetch(kind, []).map(&:last)
  end

  # The tags an admin keeps for sets, read once per page (each set and add-set form offers them).
  def set_tags
    @set_tags ||= SetTag.order(:name).to_a
  end
end
