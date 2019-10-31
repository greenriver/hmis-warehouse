class AddProjectIdIndexToInventory < ActiveRecord::Migration[4.2]
  def change
    add_index :Inventory, :ProjectID
  end
end
