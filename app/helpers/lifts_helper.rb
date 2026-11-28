# How a lift's sets and equipment are written and offered: weights ("80 kg", "Bodyweight + 10 kg"),
# a set in one line, and the admin's equipment names and set tags for the forms.
module LiftsHelper
  # "80 kg", or "Bodyweight" for a set without a weight. On a bodyweight exercise (bodyweight: true)
  # the weight is added or taken off: "Bodyweight + 10 kg", "Bodyweight − 10 kg", with "BW" in place
  # of "Bodyweight" on a phone; plain: true gives the long text alone, for a sentence (a confirm).
  def format_weight(weight, bodyweight: false, plain: false)
    return "Bodyweight" if weight.nil? && !bodyweight
    return weight_with_unit(weight, plain) unless bodyweight

    word = plain ? "Bodyweight" : bodyweight_word
    return word if weight.nil? || weight.zero?

    safe_join([word, " #{weight.negative? ? '−' : '+'} ", weight_with_unit(weight.abs, plain)])
  end

  # "80 kg"; shown (not plain) the "kg" is a quieter .unit, so the number leads.
  def weight_with_unit(weight, plain)
    return "#{weight_text(weight)} kg" if plain

    safe_join([weight_text(weight), " ", tag.span("kg", class: "unit")])
  end

  # "Bodyweight", or "BW" on a phone, where the set table has little room.
  def bodyweight_word
    safe_join([tag.span("Bodyweight", class: "d-none d-sm-inline"), tag.span("BW", class: "d-sm-none")])
  end

  # A weight as typed: up to three decimals, without trailing zeros (80, 32.5, 1.125).
  def weight_number(weight)
    number_with_precision(weight, precision: 3, strip_insignificant_zeros: true)
  end

  # A weight to read, with thousands separated (1,234.125); weight_number is the plain one for fields.
  def weight_text(weight)
    number_with_delimiter(weight_number(weight))
  end

  # A set in one line: "80 kg × 8 reps", "Bodyweight + 10 kg × 8 reps".
  def weight_and_reps(set, plain: false)
    safe_join([format_weight(set.weight_used, bodyweight: set.bodyweight?, plain:), " × #{pluralize(set.reps_completed, 'rep')}"])
  end

  # What one logged exercise has done, for its chip: "3 sets", or for cardio its time, "30 min".
  def entry_done(entry)
    return pluralize(entry.workout_sets.size, "set") unless entry.cardio?

    seconds = entry.cardio_entries.sum(&:duration_seconds)
    seconds.positive? ? duration_text(seconds) : "No time yet"
  end

  # What was done: "3 sets", the time of cardio, "30 min", or both, "3 sets · 30 min".
  # Each part stays whole with its "·" (time_parts), so no line starts with a lone separator.
  def sets_and_time(sets, seconds)
    time_parts(sets_and_time_parts(sets, seconds))
  end

  def sets_and_time_parts(sets, seconds)
    parts = []
    parts << pluralize(sets, "set") if sets.positive? || !seconds.positive?
    parts << duration_text(seconds) if seconds.positive?
    parts
  end

  # What a logged workout holds, for lists: its counts, or "Timer only" (started, nothing logged)
  # or "Nothing logged" in place of "0 exercises · 0 sets".
  def empty_log_label(log) = log.started_at ? "Timer only" : "Nothing logged"

  # A logged workout's split, for Recent workouts and History: a plain chip for the active split, and
  # for another one a solid chip with the Splits icon that says so (owner, 2026-11-28).
  def split_chip(split, active_split)
    return tag.span(split.name, class: "chip", title: split.name) if split == active_split

    tag.span(safe_join([tag.i(class: "fa-solid fa-layer-group", aria: { hidden: true }), split.name]),
             class: "chip chip-split", title: split.name, aria: { label: "From another split: #{split.name}" })
  end

  # A WorkoutSummary in one line: "2 exercises · 3 sets · 30 min".
  def summary_counts(summary)
    time_parts([pluralize(summary.exercises, "exercise"), *sets_and_time_parts(summary.sets, summary.cardio_seconds)])
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
