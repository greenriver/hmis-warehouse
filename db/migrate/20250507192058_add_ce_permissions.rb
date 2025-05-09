# frozen_string_literal: true

class AddCePermissions < ActiveRecord::Migration[7.1]
  def up
    ::Hmis::Role.ensure_permissions_exist
    ::Hmis::Role.reset_column_information
  end

  def down
    remove_column :hmis_roles, :can_view_enrollment_location_map
    remove_column :hmis_roles, :can_view_prioritized_client_lists
    remove_column :hmis_roles, :can_start_referrals
    remove_column :hmis_roles, :can_view_referrals
    remove_column :hmis_roles, :can_view_own_referrals
    remove_column :hmis_roles, :can_perform_any_referral_tasks
    remove_column :hmis_roles, :can_perform_own_referral_tasks
    remove_column :hmis_roles, :can_view_client_eligible_opportunities
    remove_column :hmis_roles, :can_assign_referral_tasks
  end
end
