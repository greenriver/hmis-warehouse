###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module UserPermissionCache
  extend ActiveSupport::Concern
  included do
    def invalidate_user_permission_cache
      User.clear_cached_permissions
    end
  end
end
