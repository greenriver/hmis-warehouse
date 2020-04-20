class AddHealthEmergencyPermissions < ActiveRecord::Migration[5.2]
  def up
    Role.ensure_permissions_exist
    Role.reset_column_information
  end

  def down
    remove_column :roles, :can_edit_health_emergency_triage
    remove_column :roles, :can_edit_health_emergency_clinical
  end
end
