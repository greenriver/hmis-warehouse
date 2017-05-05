class AddHivAndDmhPermissions < ActiveRecord::Migration
  def change
    Role.ensure_permissions_exist
    admin = Role.where(name: 'admin').first
    dnd = Role.where(name: 'dnd_staff').first
    admin.update({can_view_dmh_status: true})
    dnd.update({can_view_dmh_status: true})
    admin.update({can_view_hiv_status: true})
    dnd.update({can_view_hiv_status: true})
  end
end
