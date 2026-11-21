# Account setting: each exercise's first set of the day starts with the Warm-up tag ticked. Only adds.
class AddAutoWarmUpToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :auto_warm_up, :boolean, null: false, default: false
  end
end
