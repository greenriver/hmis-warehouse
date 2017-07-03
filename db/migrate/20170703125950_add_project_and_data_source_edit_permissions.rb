class AddProjectAndDataSourceEditPermissions < ActiveRecord::Migration
  def up
    Role.ensure_permissions_exist
    Role.reset_column_information
    Role.where( name: %w( admin dnd_staff ) ).update_all(
      can_edit_projects: true, 
      can_edit_data_sources: true,
      can_edit_organizations: true
    )
  end
  def down
    remove_column :roles, :can_edit_projects, :boolean, default: false
    remove_column :roles, :can_edit_data_sources, :boolean, default: false
    remove_column :roles, :can_edit_organizations, :boolean, default: false
  end
end
