class AddExtrapolatedConfig < ActiveRecord::Migration[5.2]
  def change
    add_column :configs, :ineligible_uses_extrapolated_days, :boolean, default: true, null: false
  end
end
