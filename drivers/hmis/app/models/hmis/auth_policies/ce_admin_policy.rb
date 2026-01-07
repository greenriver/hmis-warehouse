###
# Copyright 2016 - 2026 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Global Coordinated Entry administration policy (not tied to a specific project)
class Hmis::AuthPolicies::CeAdminPolicy < Hmis::AuthPolicies::BasePolicy
  # Whether the user can manage global CE default contacts (data source-level)
  def can_manage_contacts?
    global_permissions.include?(:can_administrate_coordinated_entry)
  end

  protected

  # todo - this (ai gen) isn't right, but I need more discussion/understanding of our future approach to "global" (data source level) permissions
  #  theron's point: >I had hoped we could avoid such global permissions by, say authorizing against a data-source or some other entity.
  # Global CE permissions are not tied to a specific resource.
  # The resource is expected to be a class (e.g., GrdaWarehouse::DataSource)
  def validate_resource!(arg)
    return if arg.is_a?(Class)

    raise ArgumentError, "CeAdminPolicy expects a Class, got #{arg.class}"
  end

  def global_permissions
    # todo @martha - use context.global_permissions once gig/8328-client-policy is merged
    context.potential_permissions
  end
end
