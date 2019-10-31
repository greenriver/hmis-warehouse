class ConfirmAllRolePermissionsExist < ActiveRecord::Migration[4.2]
  def up
    Role.ensure_permissions_exist
  end
end
