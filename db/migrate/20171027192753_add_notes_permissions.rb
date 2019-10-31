class AddNotesPermissions < ActiveRecord::Migration[4.2]
  def up
    Role.ensure_permissions_exist   
  end
  def down
    remove_column :roles, :can_edit_client_notes, :boolean, default: false
    remove_column :roles, :can_edit_window_client_notes, :boolean, default: false
  end
end
