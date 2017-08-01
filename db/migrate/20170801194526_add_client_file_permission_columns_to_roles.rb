class AddClientFilePermissionColumnsToRoles < ActiveRecord::Migration
  def up
    Role.ensure_permissions_exist
    Role.reset_column_information
    Role.where( name: %w( admin dnd_staff ) ).update_all(
      can_manage_client_files: true, 
      can_manage_window_client_files: true
    )
  end
  def down
    remove_column :roles, :can_manage_client_files, :boolean, default: false
    remove_column :roles, :can_manage_window_client_files, :boolean, default: false
  end
end
