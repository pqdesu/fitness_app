# The equipment catalogue an admin keeps (free weights, machines, machine types), the detail of a
# lift's equipment chosen from it, and an exercise's starting equipment and unilateral mark.
# Only adds: nothing existing is renamed or dropped.
class AddEquipmentCatalogue < ActiveRecord::Migration[8.1]
  def change
    create_table :equipment_items do |t|
      t.string :name, null: false
      t.string :kind, null: false
      t.timestamps
    end
    add_index :equipment_items, "kind, lower(name)", unique: true, name: "index_equipment_items_on_kind_and_name"

    # A copy of the names, like a lift's exercise name: a lift keeps its label when an item is deleted.
    [:workout_exercises, :workout_log_exercises].each do |table|
      add_column table, :equipment_name, :string
      add_column table, :machine_type, :string
    end

    # What a new planned or logged lift of the exercise starts with; the lift can still change it.
    add_column :exercises, :equipment, :string, null: false, default: "free_weights"
    add_column :exercises, :equipment_name, :string
    add_column :exercises, :machine_type, :string
    add_column :exercises, :machine_brand, :string
    add_column :exercises, :unilateral, :boolean, null: false, default: false
  end
end
