###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class Hmis::AuthPolicies::FormDefinitionPolicy < Hmis::AuthPolicies::BasePolicy
  def can_create?(role:)
    user.can_manage_forms_for_role?(role)
  end

  # Catch-all field that is resolved to frontend.
  # "Manage" form includes ability to create and edit drafts, duplicate, and publish forms.
  def can_manage_form?
    return false if form_definition.managed_in_version_control?

    # Only super-admins can manage forms that are marked as 'admin_editable_only' in the database
    return false if form_definition.admin_editable_only? && !user.can_administrate_config?

    user.can_manage_forms_for_role?(form_definition.role)
  end

  def can_create_draft? = can_manage_form?
  def can_edit_draft? = can_manage_form?
  def can_publish? = can_manage_form?

  def can_duplicate?
    # Users can duplicate forms even if they are managed in version control or admin-editable-only
    user.can_manage_forms_for_role?(form_definition.role)
  end

  def can_delete?
    form_definition.draft? && can_manage_form?
  end

  # TODO: incorporate other policies and permissions. For example, can_index? policy should be based on permission can_configure_data_collection?

  protected

  def form_definition = resource
  def validate_resource!(arg) = ensure_arg_type!(arg, Hmis::Form::Definition, allow_nil: true)
end
