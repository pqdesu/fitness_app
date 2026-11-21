# A row in an ordered list of exercises (a day's plan, a logged workout), read in position, then id
# order. A new row has no position, and PostgreSQL sorts NULL last, so it is added last. move!
# takes it one place "up" or "down" (the ⋯ menu), or to a place in the list, 1 first (a drag and
# drop). Each model says which rows are its list (siblings).
module Positioned
  # Renumbers the whole list, so unnumbered rows, gaps (removed rows) and ties cannot stop a move.
  # A place off the list moves nothing.
  def move!(to)
    transaction do
      list = siblings.order(:position, :id).lock.to_a
      from = list.index(self)
      target = { "up" => from - 1, "down" => from + 1 }.fetch(to.to_s) { to.to_i - 1 }
      return if target == from || !target.between?(0, list.size - 1)

      list.insert(target, list.delete_at(from))
      list.each.with_index(1) { |row, n| row.update_column(:position, n) unless row.position == n }
    end
  end
end
