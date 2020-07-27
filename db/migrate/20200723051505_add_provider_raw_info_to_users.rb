class AddProviderRawInfoToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :provider_raw_info, :json
  end
end
