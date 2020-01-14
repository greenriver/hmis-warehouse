class AddActiveInCasToWarehouseClientsProcessed < ActiveRecord::Migration[4.2]
  def change
    add_column :warehouse_clients_processed, :active_in_cas_match, :boolean, default: false
  end
end
