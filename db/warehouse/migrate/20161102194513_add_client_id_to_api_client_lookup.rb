class AddClientIdToApiClientLookup < ActiveRecord::Migration[4.2]
  def change
    add_column :api_client_data_source_ids, :client_id, :integer, index: true
  end
end
