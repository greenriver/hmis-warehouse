class AddOrganizationManagerToRoles < ActiveRecord::Migration
  def up
    Role.where(name: 'Organization Manager').first_or_create
    Role.ensure_permissions_exist
    Role.reset_column_information
  end

  def down
    remove_column :roles, :can_manage_organization_users, :boolean, default: false
    Role.where(name: 'Organization Manager').destroy_all
  end
end
