class AddVispdatPermissions < ActiveRecord::Migration
  def up
    Role.ensure_permissions_exist
    Role.reset_column_information
    Role.where( name: %w( admin dnd_staff ) ).update_all(
      can_view_vspdat: true,
      can_edit_vspdat: true
    )
  end
  def down
    remove_column :roles, :can_view_vspdat, :boolean, default: false
    remove_column :roles, :can_edit_vspdat, :boolean, default: false
  end
end
