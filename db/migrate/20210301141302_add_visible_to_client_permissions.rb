class AddVisibleToClientPermissions < ActiveRecord::Migration[5.2]
  def up
    Role.ensure_permissions_exist
    Role.reset_column_information
  end

  def down
    remove_column :roles, :can_view_full_client_dashboard
    remove_column :roles, :can_view_limited_client_dashboard
  end
end
