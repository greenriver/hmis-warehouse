#  Copyright 2016 - 2024 Green River Data Analysis, LLC
#
#  License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
#

module ConfigToolPermissionHelper
  extend ActiveSupport::Concern

  def ensure_form_role_permission(role)
    # NON_ADMIN_FORM_ROLES are editable by everyone with can_manage_forms permission
    return if Hmis::Form::Definition::NON_ADMIN_FORM_ROLES.include?(role)

    # All other roles are only editable by 'super-admins', those who have can_administrate_config permission
    access_denied! unless current_user.can_administrate_config?
  end
end
