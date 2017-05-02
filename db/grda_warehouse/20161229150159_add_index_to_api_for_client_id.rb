class AddIndexToApiForClientId < ActiveRecord::Migration
  def change
    add_index :api_client_data_source_ids, :client_id
    add_index :hmis_clients, :client_id
    add_index :hmis_forms, :client_id
  end
end
