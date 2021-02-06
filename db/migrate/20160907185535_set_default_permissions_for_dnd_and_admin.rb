class SetDefaultPermissionsForDNDAndAdmin < ActiveRecord::Migration[4.2]
  def up
    Role.ensure_permissions_exist
    admin = Role.where(name: 'admin').first_or_create
    dnd = Role.where(name: 'dnd_staff').first_or_create
    admin.update_attributes(Role.permissions.map{|m| [m, true]}.to_h)
    dnd.update_attributes(Role.permissions.map{|m| [m, true]}.to_h)
  end
  def down
    remove_column :roles, :can_view_census_details
    remove_column :roles, :can_view_projects
    remove_column :roles, :can_view_organizations
  end
end
