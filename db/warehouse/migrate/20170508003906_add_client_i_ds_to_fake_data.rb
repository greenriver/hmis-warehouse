class AddClientIDsToFakeData < ActiveRecord::Migration
  def change
    add_column :fake_data, :client_ids, :text
  end
end
