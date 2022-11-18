class AddDestinationIdToCePerformancClients < ActiveRecord::Migration[6.1]
  def change
    add_column :ce_performance_clients, :destination_client_id, :integer
  end
end
