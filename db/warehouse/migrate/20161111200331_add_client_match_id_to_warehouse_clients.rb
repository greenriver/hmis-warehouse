class AddClientMatchIdToWarehouseClients < ActiveRecord::Migration[4.2]
  def change
    add_column :warehouse_clients, :client_match_id, :integer
  end
end
