class AddServiceScanningViewPermission < ActiveRecord::Migration[5.2]
  def up
    Role.ensure_permissions_exist
    Role.reset_column_information
  end
  def down
    remove_column :roles, :can_view_service_register_on_client
  end
end
