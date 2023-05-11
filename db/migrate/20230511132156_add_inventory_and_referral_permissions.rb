class AddInventoryAndReferralPermissions < ActiveRecord::Migration[6.1]
  def up
    ::Hmis::Role.ensure_permissions_exist
    ::Hmis::Role.reset_column_information
  end

  def down
   remove_column :hmis_roles, :can_manage_inventory
   remove_column :hmis_roles, :can_manage_incoming_referrals
   remove_column :hmis_roles, :can_manage_outgoing_referrals
   remove_column :hmis_roles, :can_manage_denied_referrals
  end
end
