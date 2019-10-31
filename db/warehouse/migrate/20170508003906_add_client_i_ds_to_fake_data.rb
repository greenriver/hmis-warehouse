class AddClientIDsToFakeData < ActiveRecord::Migration[4.2]
  def change
    add_column :fake_data, :client_ids, :text
  end
end
