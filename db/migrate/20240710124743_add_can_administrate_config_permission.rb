class AddCanAdministrateConfigPermission < ActiveRecord::Migration[7.0]
  def up
    ::Hmis::Role.ensure_permissions_exist
    ::Hmis::Role.reset_column_information
  end

  def down
    remove_column :hmis_roles, :can_administrate_config
  end
end
