class AddNewPermissionsToRoles < ActiveRecord::Migration[6.1]
  def change
    add_column :hmis_roles, :can_edit_organization, :boolean, null: false, default: false
    add_column :hmis_roles, :can_delete_organization, :boolean, null: false, default: false
    add_column :hmis_roles, :can_edit_clients, :boolean, null: false, default: false
    add_column :hmis_roles, :can_view_partial_ssn, :boolean, null: false, default: false
    add_column :hmis_roles, :can_view_dob, :boolean, null: false, default: false
    add_column :hmis_roles, :can_view_enrollment_details, :boolean, null: false, default: false
    add_column :hmis_roles, :can_edit_enrollments, :boolean, null: false, default: false
  end
end
