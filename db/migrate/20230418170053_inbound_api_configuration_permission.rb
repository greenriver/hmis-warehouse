class InboundApiConfigurationPermission < ActiveRecord::Migration[6.1]
  def change
    add_column :roles, :can_manage_inbound_api_configurations, :boolean, default: false, null: false
  end
end
