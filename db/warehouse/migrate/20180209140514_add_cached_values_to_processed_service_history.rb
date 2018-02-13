class AddCachedValuesToProcessedServiceHistory < ActiveRecord::Migration
  def change
    add_column :warehouse_clients_processed, :first_homeless_date, :date
    add_column :warehouse_clients_processed, :last_homeless_date, :date
    add_column :warehouse_clients_processed, :homeless_days, :integer
    add_column :warehouse_clients_processed, :first_chronic_date, :date
    add_column :warehouse_clients_processed, :last_chronic_date, :date
    add_column :warehouse_clients_processed, :chronic_days, :integer
  end
end
