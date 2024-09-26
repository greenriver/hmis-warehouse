class AddCanViewProjectLocationsPermission < ActiveRecord::Migration[7.0]
  def up
    Role.ensure_permissions_exist
    Role.reset_column_information
  end

  def down
    remove_column :roles, :can_view_project_locations
  end
end
