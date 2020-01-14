class RemoveChronicallyHomelessFromProcessedClient < ActiveRecord::Migration[4.2]
  def change
    remove_column :warehouse_clients_processed, :chronically_homeless, :boolean, default: false, null: false
  end
end
