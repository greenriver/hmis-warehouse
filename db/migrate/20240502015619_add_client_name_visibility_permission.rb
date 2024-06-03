class AddClientNameVisibilityPermission < ActiveRecord::Migration[6.1]
  def up
    Role.ensure_permissions_exist
    Role.reset_column_information
  end

  def down
    remove_column :roles, :can_view_client_name
  end
end