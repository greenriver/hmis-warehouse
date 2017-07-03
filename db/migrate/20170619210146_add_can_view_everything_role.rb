class AddCanViewEverythingRole < ActiveRecord::Migration
  def up
    Role.ensure_permissions_exist
    Role.reset_column_information
    Role.where( name: %w( admin dnd_staff ) ).update_all(can_edit_anything_super_user: true)
  end
  def down
    remove_column :roles, :can_edit_anything_super_user, :boolean, default: false
  end
end
