class AddDaysHomelessPlusOverridesToWarehouseClientsProcessed < ActiveRecord::Migration
  def change
    add_column :warehouse_clients_processed, :days_homeless_plus_overrides, :integer
  end
end
