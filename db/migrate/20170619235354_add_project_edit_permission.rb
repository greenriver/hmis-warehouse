class AddProjectEditPermission < ActiveRecord::Migration
  def change
    Role.ensure_permissions_exist
    admin = Role.where(name: 'admin').first
    dnd = Role.where(name: 'dnd_staff').first
    admin.update({can_edit_project_groups: true})
    dnd.update({can_edit_project_groups: true})
  end
end
