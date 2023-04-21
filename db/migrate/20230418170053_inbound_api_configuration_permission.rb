class InboundApiConfigurationPermission < ActiveRecord::Migration[6.1]
  def up
    Role.ensure_permissions_exist
    Role.reset_column_information
  end

  def down
    remove_column :roles, :can_manage_inbound_api_configurations, :boolean, default: false, null: false
  end
end
