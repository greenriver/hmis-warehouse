###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# See: docs/domain-pack/authorization/warehouse-legacy-roles.md
# See: docs/domain-pack/authorization/warehouse-access-controls.md
module UserPermissionCache
  extend ActiveSupport::Concern
  included do
    def invalidate_user_permission_cache
      User.clear_cached_permissions
    end
  end
end
