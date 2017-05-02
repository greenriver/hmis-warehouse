class AddWindowRole < ActiveRecord::Migration
  def up
    Role.ensure_permissions_exist
    admin = Role.where(name: 'admin').first_or_create
    dnd = Role.where(name: 'dnd_staff').first_or_create
    admin.update(can_view_client_window: true)
    dnd.update(can_view_client_window: true)
  end

  def down
    remove_column :roles, :can_view_client_window, :boolean, default: false
  end
end
