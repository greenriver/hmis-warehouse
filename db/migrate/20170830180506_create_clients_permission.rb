class CreateClientsPermission < ActiveRecord::Migration
  def up
    Role.ensure_permissions_exist
    Role.reset_column_information
    Role.where( name: %w( admin ) ).update_all(
      can_create_clients: true
    )
  end
  def down
    remove_column :roles, :can_create_clients, :boolean, default: false
  end
end
