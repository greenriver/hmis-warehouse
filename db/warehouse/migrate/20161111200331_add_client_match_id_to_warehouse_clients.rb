class AddClientMatchIdToWarehouseClients < ActiveRecord::Migration
  def change
    add_column :warehouse_clients, :client_match_id, :integer
  end
end
