class AddSearchWindowPermission < ActiveRecord::Migration[4.2]
  def up
    Role.ensure_permissions_exist   
  end
  def down
    remove_column :roles, :can_search_window, :boolean, default: true
  end
end
