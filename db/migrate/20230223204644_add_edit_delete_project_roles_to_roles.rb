class AddEditDeleteProjectRolesToRoles < ActiveRecord::Migration[6.1]
  def change
    add_column :hmis_roles, :can_delete_project, :boolean, null: false, default: false
    add_column :hmis_roles, :can_edit_project_details, :boolean, null: false, default: false
  end
end
