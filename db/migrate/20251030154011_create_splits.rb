class CreateSplits < ActiveRecord::Migration[7.1]
  def change
    create_table :splits do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name

      t.timestamps
    end
  end
end
