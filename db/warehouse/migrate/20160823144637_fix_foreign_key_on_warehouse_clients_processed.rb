class FixForeignKeyOnWarehouseClientsProcessed < ActiveRecord::Migration[4.2]
  def change
    remove_foreign_key :warehouse_clients_processed, column: :client_id
    add_foreign_key :warehouse_clients_processed, :Client, column: :client_id
  end
end
