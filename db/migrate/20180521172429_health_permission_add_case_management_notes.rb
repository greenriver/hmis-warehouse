class HealthPermissionAddCaseManagementNotes < ActiveRecord::Migration[4.2][4.2]
  def up
    Role.ensure_permissions_exist
    Role.reset_column_information
  end

  def down
    remove_column :roles, :can_add_case_management_notes, :boolean, default: false
  end
end
