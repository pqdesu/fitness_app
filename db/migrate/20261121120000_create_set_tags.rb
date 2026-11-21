# Tags an admin keeps (warm-up, assisted…) and the sets they are on. Deleting a tag takes it off
# every set (the owner's choice, 2026-11-21), so the links go with it. Only adds.
class CreateSetTags < ActiveRecord::Migration[8.1]
  def change
    create_table :set_tags do |t|
      t.string :name, null: false
      t.timestamps
    end
    add_index :set_tags, "lower(name)", unique: true, name: "index_set_tags_on_name"

    create_table :workout_set_tags do |t|
      t.references :workout_set, null: false, foreign_key: { on_delete: :cascade }
      t.references :set_tag, null: false, foreign_key: { on_delete: :cascade }
    end
    add_index :workout_set_tags, [:workout_set_id, :set_tag_id], unique: true
  end
end
