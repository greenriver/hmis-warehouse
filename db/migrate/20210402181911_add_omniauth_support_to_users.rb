class AddOmniauthSupportToUsers < ActiveRecord::Migration[5.2]
  def up
    add_column :users, :provider, :string unless column_exists? :users, :provider
    add_column :users, :uid, :string unless column_exists? :users, :uid
    add_column :users, :provider_raw_info, :json unless column_exists? :users, :provider_raw_info
  end

  def down
    # dont remove them, they might have existed from other branches/optional configs
    # remove_column :users, :provider
    # remove_column :users, :uid
    # remove_column :users, :provider_raw_info
  end
end
