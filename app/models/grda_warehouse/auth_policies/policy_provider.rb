###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# policies by resource type. This could be enhanced with shared context for data loading
class GrdaWarehouse::AuthPolicies::PolicyProvider
  POLICIES = {
    client: GrdaWarehouse::AuthPolicies::ClientPolicy,
    data_source: GrdaWarehouse::AuthPolicies::DataSourcePolicy,
    project: GrdaWarehouse::AuthPolicies::ProjectPolicy,
  }.freeze

  def self.policy_for(resource_or_id, type:, user:)
    policy_class = POLICIES[type.to_sym]
    raise ArgumentError, "Unknown resource type: #{type}" unless policy_class

    policy_class.new(user: user, resource: resource_or_id)
  end
end
