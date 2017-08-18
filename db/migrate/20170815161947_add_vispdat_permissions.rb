class AddVispdatPermissions < ActiveRecord::Migration
  def up
    Role.ensure_permissions_exist
    Role.reset_column_information
  end
  def down
    remove_column :roles, :can_view_vspdat, :boolean, default: false
    remove_column :roles, :can_edit_vspdat, :boolean, default: false
  end
end
