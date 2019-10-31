class AddLastExitDestinationToWarehouseClientsProcessed < ActiveRecord::Migration[4.2]
  def change
    add_column :warehouse_clients_processed, :last_exit_destination, :string
  end
end
