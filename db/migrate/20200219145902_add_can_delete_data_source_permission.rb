class AddCanDeleteDataSourcePermission < ActiveRecord::Migration[5.2]
  def up
    Role.ensure_permissions_exist
    Role.reset_column_information
  end

  def down
    remove_column :roles, :can_delete_projects
    remove_column :roles, :can_delete_data_sources
  end
end
