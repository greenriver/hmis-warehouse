class AddNameToPerformanceMetricsClients < ActiveRecord::Migration[5.2]
  def change
    add_column :performance_metrics_clients, :first_name, :string
    add_column :performance_metrics_clients, :last_name, :string
  end
end
