###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module UserPermissionCache
  extend ActiveSupport::Concern
  included do
    def invalidate_user_permission_cache
      User.clear_cached_permissions
    end
  end
end
