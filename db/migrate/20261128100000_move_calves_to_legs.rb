# Calves is no longer a muscle group (owner, 2026-11-28): its exercises join Legs.
# Data only; master (which shares the development database) still lists Legs, so it reads them fine.
class MoveCalvesToLegs < ActiveRecord::Migration[8.1]
  def up
    execute "UPDATE exercises SET muscle_group = 'Legs' WHERE muscle_group = 'Calves'"
  end

  # Which Legs exercises were Calves is not kept, so there is nothing to put back.
  def down; end
end
