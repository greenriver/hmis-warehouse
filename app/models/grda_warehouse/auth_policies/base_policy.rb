###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###
require 'memery'

class GrdaWarehouse::AuthPolicies::BasePolicy
  attr_reader :user, :resource
  include Memery

  def initialize(user:, resource:)
    raise "unexpected user #{user.class.name}" unless user.is_a?(::User)

    @user = user
    @resource = resource.presence
  end

  def context
    user.policy_context
  end
end
