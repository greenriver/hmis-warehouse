###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# @see docs/features/warehouse/warehouse-auth-policies.md

require 'memery'

class GrdaWarehouse::AuthPolicies::UserBaseContext
  include Memery
  attr_reader :user

  EMPTY_SET = Set.new.freeze

  def initialize(user)
    raise ArgumentError, 'must be a user' unless user.is_a?(User)

    @user = user
  end

  memoize def client_roi_loader
    GrdaWarehouse::AuthPolicies::ContextLoaders::ClientRoiLoader.new(@user)
  end

  memoize def restricted_client_loader
    GrdaWarehouse::AuthPolicies::ContextLoaders::RestrictedClientLoader.new
  end

  def client_restricted?(destination_client_id)
    restricted_client_loader.restricted?(destination_client_id)
  end

  def preload_destination_client_dependencies(destination_client_ids)
    restricted_client_loader.preload(destination_client_ids)
  end
end
