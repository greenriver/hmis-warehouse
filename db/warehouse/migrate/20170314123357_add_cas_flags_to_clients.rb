class AddCasFlagsToClients < ActiveRecord::Migration
  def change
    add_column :Client, :disability_verified_on, :datetime, index: true
    add_column :Client, :housing_assistance_network_released_on, :datetime, index: true
    add_column :Client, :sync_with_cas, :boolean, default: false, null: false, index: true
  end
end
