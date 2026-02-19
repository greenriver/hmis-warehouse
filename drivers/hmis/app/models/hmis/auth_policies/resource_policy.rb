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
    policy_class = resource.is_a?(Class) ? global_policy_class : instance_policy_class
    policy_class.new(context: context, resource: resource)
  end

  def self.global_policy_class
    const_get(:Global, false)
  rescue NameError
    raise NotImplementedError, "#{name} does not have a 'Global' nested class"
  end

  def self.instance_policy_class
    const_get(:Instance, false)
  rescue NameError
    raise NotImplementedError, "#{name} does not have an 'Instance' nested class"
  end
end
