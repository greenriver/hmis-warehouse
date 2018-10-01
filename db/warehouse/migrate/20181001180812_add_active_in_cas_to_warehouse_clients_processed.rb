class AddActiveInCasToWarehouseClientsProcessed < ActiveRecord::Migration
  def change
    add_column :warehouse_clients_processed, :active_in_cas_match, :boolean, default: false
  end
end
