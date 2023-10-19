class AddHmisAdminPerms < ActiveRecord::Migration[6.1]
  def up
    Hmis::Role.ensure_permissions_exist
    Hmis::Role.reset_column_information
  end

  def down
    remove_column :hmis_roles, :can_merge_clients
    remove_column :hmis_roles, :can_split_households
    remove_column :hmis_roles, :can_transfer_enrollments
  end
end
