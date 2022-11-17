class AddSouceHashToWarehouseClient < ActiveRecord::Migration[6.1]
  def change
    add_column :warehouse_clients, :source_hash, :string
  end
end
