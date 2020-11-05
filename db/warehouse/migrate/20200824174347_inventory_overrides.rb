class InventoryOverrides < ActiveRecord::Migration[5.2]
  def change
    add_column :Inventory, :inventory_start_date_override, :date
  end
end
