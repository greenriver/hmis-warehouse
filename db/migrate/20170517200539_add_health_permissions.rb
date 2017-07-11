class AddHealthPermissions < ActiveRecord::Migration
  def up
    add_column :roles, :health_role, :boolean, default: false, null: false
    Role.ensure_permissions_exist
    Role.reset_column_information
    Role.where(name: 'Health admin').first_or_create(
      can_administer_health: true, 
      health_role: true
    )
    Role.where(name: 'Healthcare collaborator').first_or_create(
      can_edit_client_health: true,
      health_role: true
    )
  end
  def down
    remove_column :roles, :health_role, :boolean, default: false, null: false
  end
end
