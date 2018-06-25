class UpdateHpcRolePermissions < ActiveRecord::Migration
  def up
    Role.ensure_permissions_exist
    Role.reset_column_information
    # Create role structure, but only if health is enabled
    if GrdaWarehouse::Config.get(:healthcare_available)

      attributes = Hash.new(false)
      Role.health_permissions.each do |perm|
        attributes[perm] = false
      end
      role = Role.where(name: 'BHCHP Administrators').first_or_initialize
      attributes[:can_administer_health] = true
      attributes[:can_view_aggregate_health] = true
      attributes[:can_manage_health_agency] = true
      attributes[:can_approve_patient_assignments] = true
      attributes[:can_manage_claims] = true

      role.assign_attributes(attributes)
      role.save!

      
      ##########
      attributes = Hash.new(false)
      Role.health_permissions.each do |perm|
        attributes[perm] = false
      end
      role = Role.where(name: 'Health agency manager').first_or_initialize
      attributes[:can_manage_patients_for_own_agency] = true

      role.assign_attributes(attributes)
      role.save!


      ##########
      attributes = Hash.new(false)
      Role.health_permissions.each do |perm|
        attributes[perm] = false
      end
      role = Role.where(name: 'Health Partner Agency Supervisors').first_or_initialize
      attributes[:can_edit_patient_items_for_own_agency] = true
      attributes[:can_view_patients_for_own_agency] = true

      role.assign_attributes(attributes)
      role.save!


      ##########
      attributes = Hash.new(false)
      Role.health_permissions.each do |perm|
        attributes[perm] = false
      end
      role = Role.where(name: ['Health Case Workers', 'Health Case Manager', 'Health Care Manager']).first_or_initialize
      attributes[:name] = 'Health Case Manager'
      attributes[:can_edit_patient_items_for_own_agency] = true
      attributes[:can_view_patients_for_own_agency] = true

      role.assign_attributes(attributes)
      role.save!

    end

    def down
      remove_column :roles, :can_approve_patient_items_for_agency
    end
  end
end
