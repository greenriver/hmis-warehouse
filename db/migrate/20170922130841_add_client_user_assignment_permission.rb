class AddClientUserAssignmentPermission < ActiveRecord::Migration
  def up
    Role.ensure_permissions_exist
    Role.reset_column_information
  end
  def down
    remove_column :roles, :can_assign_users_to_clients, :boolean, default: false
    remove_column :roles, :can_view_client_user_assignments, :boolean, default: false
  end
end
