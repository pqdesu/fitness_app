# A row in an ordered list of exercises (a day's plan, a logged workout), read in position, then id
# order. A new row has no position, and PostgreSQL sorts NULL last, so it is added last. move!
# swaps a row with its neighbour. Each model says which rows are its list (siblings).
module Positioned
  # Renumbers the whole list, so unnumbered rows, gaps (removed rows) and ties cannot stop a move.
  def move!(direction)
    transaction do
      list = siblings.order(:position, :id).lock.to_a
      from = list.index(self)
      to = from + (direction == "up" ? -1 : 1)
      return if to.negative? || to >= list.size

      list[from], list[to] = list[to], list[from]
      list.each.with_index(1) { |row, n| row.update_column(:position, n) unless row.position == n }
    end
  end
end
