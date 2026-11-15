class AddActiveSplitToUsers < ActiveRecord::Migration[7.1]
  def change
    # The split the user is currently training. Deleting that split just clears the choice.
    add_reference :users, :active_split, foreign_key: { to_table: :splits, on_delete: :nullify }
  end
end
