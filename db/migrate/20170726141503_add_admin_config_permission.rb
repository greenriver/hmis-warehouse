class AddAdminConfigPermission < ActiveRecord::Migration
  def up
    Role.ensure_permissions_exist
    Role.reset_column_information
    Role.where( name: %w( admin dnd_staff ) ).update_all(
      can_manage_config: true, 
    )
  end
  def down
    remove_column :roles, :can_manage_config, :boolean, default: false
  end
end
