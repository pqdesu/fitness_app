# Weights were a bare decimal, with nothing fixing how many decimal places are kept.
# They now keep three (1.125 kg) and go up to 99,999.999.
class GiveWeightsThreeDecimals < ActiveRecord::Migration[7.1]
  def up
    change_column :workout_sets, :weight_used, :decimal, precision: 8, scale: 3
  end

  def down
    change_column :workout_sets, :weight_used, :decimal
  end
end
