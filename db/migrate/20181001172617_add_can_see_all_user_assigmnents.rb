class AddCanSeeAllUserAssigmnents < ActiveRecord::Migration
  def up
    Role.ensure_permissions_exist
    Role.reset_column_information
  end

  def down
    remove_column :roles, :can_view_all_user_client_assignments
  end
end
