class AddPermissionColumnsToRoles < ActiveRecord::Migration
  def up
    Role.ensure_permissions_exist
  end
  def down
    remove_column :roles, :can_view_clients, :boolean, default: false
    remove_column :roles, :can_edit_clients, :boolean, default: false
    remove_column :roles, :can_view_reports, :boolean, default: false
    remove_column :roles, :can_edit_users, :boolean, default: false
  end
end
