class AddConfigForDomesticViolenceLookback < ActiveRecord::Migration[5.2]
  def change
    add_column :configs, :domestic_violence_lookback_days, :integer, default: 0, null: false
  end
end
