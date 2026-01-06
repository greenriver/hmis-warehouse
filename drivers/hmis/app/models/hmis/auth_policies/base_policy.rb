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

  def initialize(context:, resource:)
    @context = context
    validate_resource!(resource)
    @resource = resource
  end

  protected

  # convenience
  def user = context.user

  # sanity check, is the resource what we expect
  def validate_resource!(_arg) = raise 'override this in child class'

  # validation helper
  def ensure_arg_type!(arg, klass)
    return if arg.is_a?(klass)

    # For ActiveRecord models, also accept the class itself
    return if arg.is_a?(Class) && arg < ActiveRecord::Base && arg == klass

    raise ArgumentError, "Expected a #{klass.name} got #{arg.class}"
  end
end
