class ConfirmAllRolePermissionsExist < ActiveRecord::Migration
  def up
    Role.ensure_permissions_exist
  end
end
