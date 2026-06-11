###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class Hmis::AuthPolicies::HmisUserPolicy < Hmis::AuthPolicies::ResourcePolicy
  class Instance < Hmis::AuthPolicies::BasePolicy
    def can_view?
      # Can view self; Can view other users with audit/impersonate permissions
      in_data_source? && (resource_is_self? || can_audit? || can_impersonate?)
    end

    def can_audit?
      in_data_source? && global_permissions.include?(:can_audit_users)
    end

    def can_impersonate?
      in_data_source? && !resource_is_self? && global_permissions.include?(:can_impersonate_users)
    end

    protected

    def in_data_source?
      resource.can_access_hmis_data_source?(user.hmis_data_source_id)
    end

    def resource_is_self?
      resource.id == user.id
    end

    def validate_resource!(arg) = ensure_arg_type!(arg, Hmis::User)
  end

  class Global < Hmis::AuthPolicies::BasePolicy
    def can_impersonate_users?
      global_permissions.include?(:can_impersonate_users)
    end

    def can_audit_users?
      global_permissions.include?(:can_audit_users)
    end

    # Global permission to load the full ApplicationUser list (email, audit fields, etc.)
    def can_index_application_users?
      can_audit_users? || can_impersonate_users?
    end

    # Global permission to load the user picklists only (id + name only) for filters/form builder.
    # Does not grant permission to load the full user records.
    def can_view_user_picklist?
      can_index_application_users? ||
        global_permissions.include?(:can_administrate_config) || # For FormBuilder user picklist
        global_permissions.include?(:can_audit_enrollments) || # For filtering enrollment audit events by user
        global_permissions.include?(:can_audit_clients) || # For filtering client audit events by user
        global_permissions.include?(:can_merge_clients) # For filtering client merge history by user
    end

    protected

    def validate_resource!(arg) = ensure_arg_class!(arg, Hmis::User)
  end
end
