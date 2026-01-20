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
    data_source_permissions.include?(:can_administrate_coordinated_entry)
  end

  # Whether the user can perform any referral tasks, in the whole data source.
  def can_perform_referral_tasks?
    # todo @martha - fix this
    data_source_permissions.include?(:can_perform_any_referral_tasks)
  end

  protected

  def validate_resource!(arg) = ensure_arg_type!(arg, GrdaWarehouse::DataSource)

  def data_source_permissions
    context.data_source_permissions
  end
end
