###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###
# frozen_string_literal: true

require 'memery'

# Resolves access group IDs into final permission sets for a user.
module Hmis::AuthPolicies::ContextLoaders
  class HmisPermissionLoader
    include Memery
    EMPTY_SET = Set.new.freeze

    def initialize(user)
      @user = user
    end

    memoize def for_access_group_ids(access_group_ids)
      return EMPTY_SET if access_group_ids.blank?

      Hmis::Role.joins(:access_controls).
        merge(@user.access_controls.where(access_group_id: access_group_ids)).
        flat_map(&:granted_permissions).to_set.freeze
    end
  end
end
