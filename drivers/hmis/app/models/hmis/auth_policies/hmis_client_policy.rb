###
# Copyright Green River Data Group, Inc.
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

    def can_delete?
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

    def can_index_files?
      # User can index files if they can manage own files (global perm),
      # or can view nonconfidential or confidential files for this client
      global_permissions.include?(:can_manage_own_client_files) ||
        client_permissions.include?(:can_view_any_nonconfidential_client_files) ||
        client_permissions.include?(:can_view_any_confidential_client_files)
    end

    def can_create_file?
      return false unless can_index_files?

      # User can create a file if they can manage "any" (meaning "all" in this case) files for this client,
      # OR if they can manage own files (global perm)
      client_permissions.include?(:can_manage_any_client_files) || global_permissions.include?(:can_manage_own_client_files)
    end

    protected

    def validate_resource!(arg) = ensure_arg_type!(arg, Hmis::Hud::Client)

    # Get permissions for the specific client instance, based on the projects they are enrolled in
    memoize def client_permissions
      context.client_permissions(resource.id)
    end
  end

  class Global < Hmis::AuthPolicies::BasePolicy
    def can_view?
      global_permissions.include?(:can_view_clients)
    end

    def can_create?
      global_permissions.include?(:can_edit_clients)
    end

    def can_edit?
      global_permissions.include?(:can_edit_clients)
    end

    def can_merge_clients?
      global_permissions.include?(:can_merge_clients)
    end

    # Whether the user can view DOB for *some* clients in the data source.
    # This global permission is used on the frontend to determine whether to show the column title as "DOB" or "Age" in Client Search.
    def can_view_dob?
      global_permissions.include?(:can_view_dob)
    end

    # Whether the user can view client alerts for *some* clients in the data source.
    # The global permission is used mainly as an optimization on the frontend to skip the query if the user doesn't have any access.
    def can_view_client_alerts?
      global_permissions.include?(:can_view_client_alerts)
    end

    protected

    def validate_resource!(arg) = ensure_arg_class!(arg, Hmis::Hud::Client)
  end
end
