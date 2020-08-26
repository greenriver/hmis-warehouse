class AddConflictColumnsToAprClients < ActiveRecord::Migration[5.2]
  def change
    change_table :hud_report_apr_clients do |t|
      t.references :client
      t.integer :data_source_id

      t.index [:client_id, :data_source_id], unique: true
    end
  end
end
