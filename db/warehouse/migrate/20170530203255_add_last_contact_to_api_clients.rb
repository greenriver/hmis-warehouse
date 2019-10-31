class AddLastContactToApiClients < ActiveRecord::Migration[4.2][4.2]
  def change
    add_column :api_client_data_source_ids, :last_contact, :date
  end
end
