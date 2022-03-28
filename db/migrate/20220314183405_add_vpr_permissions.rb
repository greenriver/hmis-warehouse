class AddVprPermissions < ActiveRecord::Migration[6.1]
  def up
    Role.ensure_permissions_exist
    Role.reset_column_information
  end

  def down
    remove_column :roles, :can_view_all_vprs
    remove_column :roles, :can_view_my_vprs
  end
end
