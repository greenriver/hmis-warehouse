###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###
require 'memery'

class GrdaWarehouse::AuthPolicies::BasePolicy
  attr_reader :context, :resource
  include Memery

  def initialize(context:, resource:)
    @context = context
    validate_resource!(resource)
    @resource = resource
  end

  protected

  def user
    context.user
  end

  def validate_resource!(_arg)
    raise 'override this in child class'
  end

  def ensure_arg_type!(arg, klass)
    raise ArgumentError, "Expected a #{klass.name} got #{arg.class}" unless arg.is_a?(klass)
  end
end
