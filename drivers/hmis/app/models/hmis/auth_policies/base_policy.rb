# frozen_string_literal: true

###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'memery'

class Hmis::AuthPolicies::BasePolicy
  attr_reader :context, :resource
  # used in child policy classes
  include Memery

  def self.for_resource(context:, resource:)
    new(context: context, resource: resource)
  end

  def initialize(context:, resource:)
    @context = context
    validate_resource!(resource)
    @resource = resource
  end

  protected

  # convenience
  def user = context.user

  # Set of permissions that the user has in the current data source (across all projects)
  def global_permissions = context.global_permissions

  # sanity check, is the resource what we expect. must be implemented by child policy
  def validate_resource!(_arg) = raise NotImplementedError, 'must implement in subclass'

  # validation helper for instances
  def ensure_arg_type!(arg, klass)
    return if arg.is_a?(klass)

    raise ArgumentError, "Expected an instance of #{klass.name} got #{arg.class}"
  end

  # validation helper for classes
  def ensure_arg_class!(arg, klass)
    return if arg == klass

    raise ArgumentError, "Expected the #{klass.name} class, got #{arg.inspect}"
  end
end
