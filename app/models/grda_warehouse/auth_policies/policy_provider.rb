###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# policies by resource type. This could be enhanced with shared context for data loading
class GrdaWarehouse::AuthPolicies::PolicyProvider
  def self.policy_for(resource:, context:)
    policy_class(resource).new(resource: resource, context: context)
  end

  # this could be in a policy_class method on the resource itself
  def self.policy_class(resource)
    case resource
    when GrdaWarehouse::Hud::Client
      if resource.destination?
        GrdaWarehouse::AuthPolicies::DestinationClientPolicy
      else
        GrdaWarehouse::AuthPolicies::SourceClientPolicy
      end
    when GrdaWarehouse::Hud::Project
      GrdaWarehouse::AuthPolicies::ProjectPolicy
    when GrdaWarehouse::DataSource
      GrdaWarehouse::AuthPolicies::DataSourcePolicy
    else
      raise ArgumentError, "Unknown resource type: #{resource}"
    end
  end
end
