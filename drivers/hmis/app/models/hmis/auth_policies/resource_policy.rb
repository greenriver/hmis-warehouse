###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Shared selector for policies that split into:
# - `Global` policy when the "resource" is a Class (i.e., the model class)
# - `Instance` policy when the "resource" is a record instance
#
# Usage:
# class Hmis::AuthPolicies::SomethingPolicy < Hmis::AuthPolicies::ResourcePolicy
#   class Instance < Hmis::AuthPolicies::BasePolicy; end
#   class Global < Hmis::AuthPolicies::BasePolicy; end
# end
class Hmis::AuthPolicies::ResourcePolicy
  def self.for_resource(context:, resource:)
    policy_class = resource.is_a?(Class) ? const_get(:Global) : const_get(:Instance)
    policy_class.new(context: context, resource: resource)
  end
end
