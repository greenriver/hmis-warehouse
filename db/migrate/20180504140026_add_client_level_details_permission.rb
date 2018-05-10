class AddClientLevelDetailsPermission < ActiveRecord::Migration
  def up
    Role.ensure_permissions_exist
    Role.reset_column_information
  end
  def down
    remove_column :roles, :can_view_project_data_quality_client_details, :boolean, default: false
  end
end
