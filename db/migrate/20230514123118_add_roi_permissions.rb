class AddRoiPermissions < ActiveRecord::Migration[6.1]
  def up
    Role.ensure_permissions_exist
    Role.reset_column_information
  end

  def down
    remove_column :roles, :can_search_clients_with_roi
    remove_column :roles, :can_view_client_enrollments_with_roi
  end
end
