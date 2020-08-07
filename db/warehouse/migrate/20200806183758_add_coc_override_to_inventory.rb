class AddCoCOverrideToInventory < ActiveRecord::Migration[5.2]
  def change
    add_column :Inventory, :coc_code_override, :string
  end
end
