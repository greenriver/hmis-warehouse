class AddLastExitDestinationToWarehouseClientsProcessed < ActiveRecord::Migration
  def change
    add_column :warehouse_clients_processed, :last_exit_destination, :string
  end
end
