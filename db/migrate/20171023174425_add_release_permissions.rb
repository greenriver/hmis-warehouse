class AddReleasePermissions < ActiveRecord::Migration
  def up
    Role.ensure_permissions_exist
    Role.reset_column_information
  end
  def down
    remove_column :roles, :can_confirm_housing_release, :boolean, default: false
  end
end
