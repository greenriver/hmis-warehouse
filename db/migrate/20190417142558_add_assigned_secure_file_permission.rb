class AddAssignedSecureFilePermission < ActiveRecord::Migration
  def up
    Role.ensure_permissions_exist
    Role.reset_column_information
  end

  def down
    remove_column :roles, :can_view_assigned_secure_uploads
  end
end
