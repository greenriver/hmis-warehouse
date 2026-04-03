###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class Hmis::AuthPolicies::HmisClientPolicy < Hmis::AuthPolicies::ResourcePolicy
  class Instance < Hmis::AuthPolicies::BasePolicy
    def can_view?
      client_permissions.include?(:can_view_clients)
    end

    def can_edit?
      client_permissions.include?(:can_edit_clients)
    end

    def can_destroy?
      client_permissions.include?(:can_delete_clients)
    end

    def can_view_name?
      client_permissions.include?(:can_view_client_name)
    end

    def can_manage_alerts?
      client_permissions.include?(:can_manage_client_alerts)
    end

    def can_manage_scan_cards?
      client_permissions.include?(:can_manage_scan_cards)
    end

    def can_view_partial_ssn?
      client_permissions.include?(:can_view_partial_ssn)
    end

    def can_view_full_ssn?
      client_permissions.include?(:can_view_full_ssn)
    end

    def can_view_client_photo?
      client_permissions.include?(:can_view_client_photo)
    end

    def can_view_dob?
      client_permissions.include?(:can_view_dob)
    end

    # Whether the user has permission to audit this client
    def can_audit?
      client_permissions.include?(:can_audit_clients)
    end

    # Whether the user has permission to view alerts for this client
    def can_view_alerts?
      client_permissions.include?(:can_view_client_alerts)
    end

    # Whether the user has permission to print case notes for this client. Does not grant expanded visibility for case notes themselves.
    def can_print_case_notes?
      client_permissions.include?(:can_print_client_case_notes)
    end

    # Whether the user has permission to view enrollment details on some enrollment(s) for this client.
    # WARNING: use the Enrollment policy to authorize access to a specific enrollment, not this method.
    def can_view_some_enrollment_details?
      client_permissions.include?(:can_view_enrollment_details)
    end

    # Whether the user has permission to manage all client files for this client that they can see (renamed from 'any' for clarity)
    def can_manage_all_viewable_client_files?
      client_permissions.include?(:can_manage_any_client_files)
    end

    # Whether the user has permission to manage their own client files for this client
    def can_manage_own_client_files?
      client_permissions.include?(:can_manage_own_client_files)
    end

    # Whether the user has permission to upload client files for this client
    def can_upload_client_files?
      client_permissions.include?(:manage_any_client_files) || client_permissions.include?(:manage_own_client_files)
    end

    # Whether the user has permission to view SOME client files for this client
    # WARNING: use the File#viewable_by to authorize access to a specific file, not this method.
    def can_view_some_client_files?
      client_permissions.include?(:can_view_any_nonconfidential_client_files) ||
        client_permissions.include?(:can_view_any_confidential_client_files) ||
        client_permissions.include?(:can_manage_own_client_files)
    end

    protected

    def validate_resource!(arg) = ensure_arg_type!(arg, Hmis::Hud::Client)

    # Get permissions for the specific client instance, based on the projects they are enrolled in
    memoize def client_permissions
      context.client_permissions(resource.id)
    end
  end

  class Global < Hmis::AuthPolicies::BasePolicy
    def can_create?
      global_permissions.include?(:can_edit_clients)
    end

    def can_edit?
      global_permissions.include?(:can_edit_clients)
    end

    def can_merge_clients?
      global_permissions.include?(:can_merge_clients)
    end

    # Whether the user has permission to view CE opportunities for all Clients in the current DataSource (Global admin permission)
    def can_view_client_eligible_opportunities?
      global_permissions.include?(:can_view_client_eligible_opportunities)
    end

    protected

    def validate_resource!(arg) = ensure_arg_class!(arg, Hmis::Hud::Client)
  end
end
