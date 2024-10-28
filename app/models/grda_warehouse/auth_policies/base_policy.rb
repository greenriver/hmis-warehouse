###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'memery'
class GrdaWarehouse::AuthPolicies::BasePolicy
  include Memery
  attr_reader :user, :resource

  def initialize(user:, resource:)
    raise "unexpected user #{user.class.name}" unless user.is_a?(::User)

    @user = user
    @resource = resource.presence
  end

  def id_from_arg(arg, resource_class)
    case arg
    when Integer, String
      arg.to_i
    when resource_class
      arg.id
    else
      raise ArgumentError, "Invalid argument: #{arg.inspect}"
    end
  end

  def resource_from_arg(arg, resource_class)
    case arg
    when Integer, String
      resource_class.find(arg.to_i)
    when resource_class
      arg
    else
      raise ArgumentError, "Invalid argument: #{arg.inspect}"
    end
  end

  memoize def system_access_group_ids(group_name)
    [AccessGroup.system_groups[group_name]&.id].compact
  end

  memoize def system_collection_ids(group_name)
    [Collection.system_collection(group_name)&.id].compact
  end
end
