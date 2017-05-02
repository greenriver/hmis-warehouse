class CreateHudPerformanceUnduplicatedClientsNew < ActiveRecord::Migration
  def change
    create_table :clients_unduplicated do |t|
      t.string :client_unique_id, null: false
      t.integer :unduplicated_client_id, null: false
      t.integer :dc_id
    end
    add_index :clients_unduplicated, :unduplicated_client_id, name: 'unduplicated_clients_unduplicated_client_id' 
  end
end
