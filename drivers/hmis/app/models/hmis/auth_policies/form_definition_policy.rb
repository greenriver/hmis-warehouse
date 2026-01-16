###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class Hmis::AuthPolicies::FormDefinitionPolicy < Hmis::AuthPolicies::ResourcePolicy
  class Instance < Hmis::AuthPolicies::BasePolicy
    # Catch-all field that is resolved to frontend.
    # "Manage" form includes ability to create and edit drafts, duplicate, and publish forms.
    def can_manage_form?
      return false if form_definition.managed_in_version_control?

      # Only super-admins can manage forms that are marked as 'admin_editable_only' in the database
      return false if form_definition.admin_editable_only? && !global_permissions.include?(:can_administrate_config)

      can_manage_form_by_role?
    end

    # Whether the user can create a draft version of the form definition
    def can_create_draft? = can_manage_form?

    # Whether the user can edit a draft version of the form definition
    def can_edit_draft? = can_manage_form?

    # Whether the user can publish the form definition
    def can_publish? = can_manage_form?

    # Whether the user can duplicate the form definition
    def can_duplicate?
      # Users can duplicate forms even if they are managed in version control or admin-editable-only
      can_manage_form_by_role?
    end

    # Whether the user can delete the form definition (only draft forms can be deleted)
    def can_delete?
      form_definition.draft? && can_manage_form?
    end

    # Whether the user can add a new Hmis::Form::Instance to the form definition
    def can_add_form_rule?
      global_permissions.include?(:can_configure_data_collection) && manageable_form_role?
    end

    # Whether the user can delete a Hmis::Form::Instance rule from the form definition
    def can_delete_form_rule? = can_add_form_rule?

    protected

    # Determines if the current user can manage forms for a given role.
    # can_manage_forms permission grants access to edit certain form roles (SERVICE, CUSTOM_ASSESSMENT),
    # while "super-admin" permission can_administrate_config grants access to edit all form roles.
    def can_manage_form_by_role?
      global_permissions.include?(:can_manage_forms) && manageable_form_role?
    end

    # Determines if the form role is considered a non-super-admin form or a super-admin form
    def manageable_form_role?
      form_definition.role.to_s.in?(Hmis::Form::Definition::NON_ADMIN_FORM_ROLES) || global_permissions.include?(:can_administrate_config)
    end

    # Form management permissions are currently global. In the future they should be tied to data source (#6612, #6691),
    # to support multi-CoC HMIS installations where each CoC manages their own set of forms.
    def global_permissions
      context.global_permissions
    end

    def form_definition = resource

    def validate_resource!(arg) = ensure_arg_type!(arg, Hmis::Form::Definition)
  end

  class Global < Hmis::AuthPolicies::BasePolicy
    # Whether the user can create an entirely new form definition (class-scoped)
    def can_create?(role:)
      can_manage_form_by_role?(role: role)
    end

    protected

    def can_manage_form_by_role?(role:)
      global_permissions.include?(:can_manage_forms) && manageable_form_role?(role: role)
    end

    def manageable_form_role?(role:)
      return false if role.nil?

      role.to_s.in?(Hmis::Form::Definition::NON_ADMIN_FORM_ROLES) || global_permissions.include?(:can_administrate_config)
    end

    def validate_resource!(arg) = ensure_arg_class!(arg, Hmis::Form::Definition)
  end
end
