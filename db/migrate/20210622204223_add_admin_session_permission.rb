class AddAdminSessionPermission < ActiveRecord::Migration[5.2]
  def up
    Role.ensure_permissions_exist
    Role.reset_column_information
    Role.where( name: %w( admin dnd_staff ) ).update_all(
      can_manage_sessions: true, 
    )
  end
  def down
    remove_column :roles, :can_manage_sessions, :boolean, default: false
  end
end
