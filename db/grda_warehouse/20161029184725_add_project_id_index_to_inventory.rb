class AddProjectIdIndexToInventory < ActiveRecord::Migration
  def change
    add_index :Inventory, :ProjectID
  end
end
