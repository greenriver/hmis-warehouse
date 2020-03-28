class RenameEmergencyTriagePermission < ActiveRecord::Migration[5.2]
  def up
    remove_column :roles, :can_edit_health_emergency_triage

    Role.ensure_permissions_exist
    Role.reset_column_information
  end

  def down
    remove_column :roles, :can_edit_health_emergency_screening
    remove_column :roles, :can_see_health_emergency_history
  end
end
