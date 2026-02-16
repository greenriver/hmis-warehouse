###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# @see docs/features/warehouse-auth-policies.md

require 'memery'

class GrdaWarehouse::AuthPolicies::UserBaseContext
  include Memery
  attr_accessor :user

  EMPTY_SET = Set.new.freeze

  def initialize(user)
    raise ArgumentError, 'must be a user' unless user.is_a?(User)
    @user = user
  end

  memoize def client_roi_loader
    GrdaWarehouse::AuthPolicies::ContextLoaders::ClientRoiLoader.new(@user)
  end

end
