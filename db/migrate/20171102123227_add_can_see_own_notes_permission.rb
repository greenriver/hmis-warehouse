class AddCanSeeOwnNotesPermission < ActiveRecord::Migration
  def up
    Role.ensure_permissions_exist   
  end
  def down
    remove_column :roles, :can_see_own_window_client_notes, :boolean, default: false
  end
end
