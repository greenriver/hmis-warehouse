###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# policies by resource type. This could be enhanced with shared context for data loading
class GrdaWarehouse::AuthPolicies::PolicyProvider
  def self.policy_for(resource, type:, user:)
    policy_class(resource).new(user: user, resource: resource_or_id)
  end

  # this should probably be in a policy_class method on the resource itself
  def self.policy_class(resource)
    case [resource]
    when [GrdaWarehouse::Hud::Client]
      if resource.destination?
        GrdaWarehouse::AuthPolicies::DestinationClientPolicy
      else
        GrdaWarehouse::AuthPolicies::SourceClientPolicy
      end
    when [GrdaWarehouse::Hud::Project]
      GrdaWarehouse::AuthPolicies::ProjectPolicy
    when [GrdaWarehouse::Hud::DataSource]
      GrdaWarehouse::AuthPolicies::DataSourcePolicy
    else
      raise ArgumentError, "Unknown resource type: #{resource}" unless policy_class
    end
  end
end
