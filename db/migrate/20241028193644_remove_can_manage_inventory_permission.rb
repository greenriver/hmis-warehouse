class RemoveCanManageInventoryPermission < ActiveRecord::Migration[7.0]
  def up
    safety_assured do
      remove_column :hmis_roles, :can_manage_inventory
    end
  end

  def down
    # This won't really restore the column if it hasn't been added back in the rails code.
    ::Hmis::Role.ensure_permissions_exist
    ::Hmis::Role.reset_column_information
  end
end
