class IndexProcessedServiceHistory < ActiveRecord::Migration[4.2]
  def change
    add_index :warehouse_clients_processed, :homeless_days
    add_index :warehouse_clients_processed, :chronic_days
    add_index :warehouse_clients_processed, :days_served
  end
end
