class AddYouthIntakePermissions < ActiveRecord::Migration
  def up
    Role.ensure_permissions_exist
    Role.reset_column_information
  end

  def down
    remove_column :roles, :can_view_youth_intake
    remove_column :roles, :can_edit_youth_intake
  end
end
