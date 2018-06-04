class AddDataSourceWindowPermission < ActiveRecord::Migration
  def up
    Role.ensure_permissions_exist
    Role.reset_column_information
  end
  def down
    remove_column :roles, :can_see_clients_in_window_for_assigned_data_sources, :boolean, default: false
  end
end
