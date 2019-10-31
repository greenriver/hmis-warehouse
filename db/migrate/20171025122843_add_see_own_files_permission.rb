class AddSeeOwnFilesPermission < ActiveRecord::Migration[4.2]
  def up
    Role.ensure_permissions_exist   
  end
  def down
    remove_column :roles, :can_see_own_file_uploads, :boolean, default: false
  end
end
