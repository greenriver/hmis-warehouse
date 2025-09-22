###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Determines a user's permissions for Form Definitions.
class Hmis::AuthPolicies::FormDefinitionPolicy < Hmis::AuthPolicies::BasePolicy
  def can_manage_form?
    return false if resource.managed_in_version_control?
    return false if resource.admin_editable_only? && !context.user.can_administrate_config?

    context.user.can_manage_forms_for_role?(resource.role)
  end

  protected

  def validate_resource!(arg) = ensure_arg_type!(arg, Hmis::Form::Definition)
end
