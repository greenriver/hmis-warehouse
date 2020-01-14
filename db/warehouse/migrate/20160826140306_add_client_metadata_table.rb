class AddClientMetadataTable < ActiveRecord::Migration[4.2]
  def change
    add_column :warehouse_clients_processed, :days_served, :integer
    add_column :warehouse_clients_processed, :first_date_served, :date 
    add_column :warehouse_clients_processed, :last_date_served, :date
  end
end
