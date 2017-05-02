class RenameWarehouseClientId < ActiveRecord::Migration
  def change
    rename_column :warehouse_clients_processed, :warehouse_client_id, :client_id
    rename_column :warehouse_client_service_history, :unduplicated_client_id, :client_id
    add_column :warehouse_clients_processed, :last_service_updated_at, :datetime
  end
end
