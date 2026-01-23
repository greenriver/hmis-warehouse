###
# Copyright 2016 - 2026 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Global Coordinated Entry administration policy (not tied to a specific project)
class Hmis::AuthPolicies::CeAdminPolicy < Hmis::AuthPolicies::BasePolicy
  # Whether the user can manage CE default contacts in their data source.
  def can_manage_ce_default_contacts?
    # This is a global permission, so the policy returns true if the user has this permission at any entity in the data source.
    data_source_permissions.include?(:can_administrate_coordinated_entry)
  end

  # Whether the user can perform referral tasks at any entity in the data source.
  def can_perform_referral_tasks?
    data_source_permissions.include?(:can_perform_any_referral_tasks)
  end

  protected

  def validate_resource!(arg) = ensure_arg_type!(arg, GrdaWarehouse::DataSource)

  def data_source_permissions
    context.data_source_permissions
  end
end
