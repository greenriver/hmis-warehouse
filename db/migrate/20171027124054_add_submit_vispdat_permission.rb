class AddSubmitVispdatPermission < ActiveRecord::Migration
  def up
    Role.ensure_permissions_exist   
  end
  def down
    remove_column :roles, :can_submit_vspdat, :boolean, default: false
  end
end
