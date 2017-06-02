class AddLastContactToApiClients < ActiveRecord::Migration
  def change
    add_column :api_client_data_source_ids, :last_contact, :date
  end
end
