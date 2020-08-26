class AddConflictColumnsToAprClients < ActiveRecord::Migration[5.2]
  def change
    change_table :hud_report_apr_clients do |t|
      t.integer :client_id
      t.integer :data_source_id
      t.integer :report_instance_id

      t.index [:client_id, :data_source_id, :report_instance_id], unique: true,  name: 'apr_client_conflict_columns'
    end
  end
end
