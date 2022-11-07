class AddHmisAdminPermissions < ActiveRecord::Migration[6.1]
  def up
     ::Hmis::Role.ensure_permissions_exist
     ::Hmis::Role.reset_column_information
   end

   def down
    remove_column :hmis_roles, :can_administer_hmis
    remove_column :hmis_roles, :can_delete_assigned_project_data
    remove_column :hmis_roles, :can_delete_enrollments
   end
end
