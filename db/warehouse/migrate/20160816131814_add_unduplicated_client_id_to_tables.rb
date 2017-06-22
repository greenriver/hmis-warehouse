class AddUnduplicatedClientIdToTables < ActiveRecord::Migration
  def change
    remove_column :warehouse_clients, :unduplicated_client_id, :integer

    add_column :warehouse_clients, :source_id, :integer
    add_column :warehouse_clients, :destination_id, :integer, index: true

    add_foreign_key :warehouse_clients, 'Client', column: :source_id, index: true, unique: true
    add_foreign_key :warehouse_clients, 'Client', column: :destination_id, index: true

    add_index :warehouse_clients, :source_id, unique: true
  end
end
