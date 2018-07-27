class AddWhitelistedUploadsPermission < ActiveRecord::Migration
  def up
    Role.ensure_permissions_exist
    Role.reset_column_information
  end

  def down
    remove_column :roles, :can_upload_whitelisted_hud_hmis_files
  end
end
