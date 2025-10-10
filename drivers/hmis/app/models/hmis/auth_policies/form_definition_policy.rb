###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class Hmis::AuthPolicies::FormDefinitionPolicy < Hmis::AuthPolicies::BasePolicy
  def can_manage_form?
    return false if resource.managed_in_version_control?

    # Only super-admins can manage forms that are admin-editable-only
    return false if resource.admin_editable_only? && !context.user.can_administrate_config?

    context.user.can_manage_forms_for_role?(resource.role)
  end

  def can_publish_form?
    # Currently same as can_manage_form?, but may diverge in the future
    can_manage_form?
  end

  def can_update_form?(new_role: nil)
    # If the form role has been changed, confirm the user also has permission for the new role.
    return false unless can_manage_form?
    return true if new_role.blank?

    user.can_manage_forms_for_role?(new_role)
  end

  # TODO: incorporate other policies and permissions. For example, can_index? policy should be based on permission can_configure_data_collection?

  protected

  def validate_resource!(arg) = ensure_arg_type!(arg, Hmis::Form::Definition)
end
