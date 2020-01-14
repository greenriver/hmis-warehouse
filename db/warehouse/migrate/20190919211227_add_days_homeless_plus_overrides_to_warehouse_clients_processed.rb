class AddDaysHomelessPlusOverridesToWarehouseClientsProcessed < ActiveRecord::Migration[4.2]
  def change
    add_column :warehouse_clients_processed, :days_homeless_plus_overrides, :integer
  end
end
