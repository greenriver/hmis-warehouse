class CareHubPermissions < ActiveRecord::Migration
  def up
    # This only applies to Boston
    return

    Role.ensure_permissions_exist
    Role.reset_column_information
    # Create role structure, but only if health is enabled
    if GrdaWarehouse::Config.get(:healthcare_available)

      role = Role.where(name: 'BHCHP Administrators').first_or_initialize
      role.assign_attributes(
        health_role: true,
        can_approve_patient_assignments: true,
        can_manage_claims: true,
      )
      role.save!

      role = Role.where(name: 'Health Partner Agency Supervisors').first_or_initialize
      role.assign_attributes(
        health_role: true,
        can_manage_patients_for_own_agency: true,
        can_edit_patient_items_for_own_agency: true,
        can_create_care_plans_for_own_agency: true,
        can_view_patients_for_own_agency: true,
      )
      role.save!

      role = Role.where(name: 'Health Case Workers').first_or_initialize
      role.assign_attributes(
        health_role: true,
        can_edit_patient_items_for_own_agency: true,
        can_create_care_plans_for_own_agency: true,
        can_view_patients_for_own_agency: true,
      )
      role.save!

    end
  end
  def down
    permissions.each do |perm|
      remove_column :roles, perm, :boolean, default: false
    end
  end

  def permissions
    [
      :can_approve_patient_assignments,
      :can_manage_claims,
      :can_manage_all_patients,
      :can_manage_patients_for_own_agency,
      :can_edit_all_patient_items,
      :can_edit_patient_items_for_own_agency,
      :can_create_care_plans_for_own_agency,
      :can_view_all_patients, # Read-only
      :can_view_patients_for_own_agency, # Read-only
    ]
  end
end
