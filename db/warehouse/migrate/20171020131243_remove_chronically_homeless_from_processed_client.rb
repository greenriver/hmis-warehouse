class RemoveChronicallyHomelessFromProcessedClient < ActiveRecord::Migration
  def change
    remove_column :warehouse_clients_processed, :chronically_homeless, :boolean, default: false, null: false
  end
end
