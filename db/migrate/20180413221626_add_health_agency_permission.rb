class AddHealthAgencyPermission < ActiveRecord::Migration
  def up
    add_column :roles, :can_manage_health_agency, :boolean, default: false, null: false
    Role.ensure_permissions_exist
    Role.where(name: 'Health agency manager').first_or_create(
      can_manage_health_agency: true,
      health_role: true
    )
  end
  def down
    remove_column :roles, :can_manage_health_agency, :boolean, default: false, null: false
  end
end
