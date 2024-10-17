class AddCanViewUnitsPermission < ActiveRecord::Migration[7.0]
  def up
    ::Hmis::Role.ensure_permissions_exist
    ::Hmis::Role.reset_column_information
    ::Hmis::Role.where(can_manage_inventory: true).update_all(can_view_units: true, can_manage_units: true)
  end

  def down
    remove_column :hmis_roles, :can_view_units
  end
end
