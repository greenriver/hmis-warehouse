class AddFilePermissionsToRoles < ActiveRecord::Migration[6.1]
  def change
    add_column :hmis_roles, :can_manage_client_files, :boolean, null: false, default: false
  end
end
