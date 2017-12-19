class UpdateIndexesOnProjectCoC < ActiveRecord::Migration
  def change
    remove_index("ProjectCoC", ["data_source_id"])
    add_index :ProjectCoC, [:data_source_id, :ProjectID, :CoCCode]
    remove_index("Inventory", ["ProjectID"])
    add_index :Inventory, [:ProjectID, :CoCCode, :data_source_id]
  end
end
