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

  # validation helper for instances.
  # checks that resource has the correct class, and if it has a data source, that it belongs to the current user's data source
  def ensure_arg_type!(arg, klass)
    raise ArgumentError, "Expected an instance of #{klass.name} got #{arg.class}" unless arg.is_a?(klass)
    raise ArgumentError, "Expected instance #{arg.klass.name}#{arg.id} to belong to data source #{user.hmis_data_source_id}, got #{arg.data_source_id}" if arg.respond_to?(:data_source_id) && arg.data_source_id != user.hmis_data_source_id
  end

  # validation helper for classes
  def ensure_arg_class!(arg, klass)
    return if arg == klass

    raise ArgumentError, "Expected the #{klass.name} class, got #{arg.inspect}"
  end
end
