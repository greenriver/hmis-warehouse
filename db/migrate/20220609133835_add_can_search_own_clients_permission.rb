class AddCanSearchOwnClientsPermission < ActiveRecord::Migration[6.1]
  def up
    Role.ensure_permissions_exist
    Role.reset_column_information
  end

  def down
    remove_column :roles, :can_search_own_clients
  end
end
