class AddProjectRolesToRoles < ActiveRecord::Migration
  def up
    
    admin = Role.where(name: 'admin').first_or_create
    dnd = Role.where(name: 'dnd_staff').first_or_create
    admin.update({can_view_projects: true, can_view_organizations: true})
    dnd.update({can_view_projects: true, can_view_organizations: true})
  end
end
