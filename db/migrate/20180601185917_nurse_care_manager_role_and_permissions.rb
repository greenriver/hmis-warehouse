class NurseCareManagerRoleAndPermissions < ActiveRecord::Migration
  def change
    return

    Role.ensure_permissions_exist
    Role.reset_column_information

    if GrdaWarehouse::Config.get(:healthcare_available)
      attributes = Hash.new(false)
      Role.health_permissions.each do |perm|
        attributes[perm] = false
      end
      role = Role.where(name: 'Nurse Care Manager').first_or_initialize
      attributes[:health_role] = true
      attributes[:can_approve_cha] = true
      attributes[:can_approve_ssm] = true
      attributes[:can_approve_release] = true
      attributes[:can_approve_participation] = true
      attributes[:can_edit_patient_items_for_own_agency] = true
      attributes[:can_view_patients_for_own_agency] = true

      role.assign_attributes(attributes)
      role.save!

      ##########
      attributes = Hash.new(false)
      Role.health_permissions.each do |perm|
        attributes[perm] = false
      end
      role = Role.where(name: 'Health Partner Agency Supervisors').first_or_initialize
      attributes[:can_approve_cha] = true
      attributes[:can_approve_ssm] = true
      attributes[:can_approve_release] = true
      attributes[:can_approve_participation] = true
      attributes[:can_edit_patient_items_for_own_agency] = true
      attributes[:can_view_patients_for_own_agency] = true

      role.assign_attributes(attributes)
      role.save!

    end
  end
end
