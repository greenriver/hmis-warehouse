###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class Hmis::AuthPolicies::HmisClientPolicy
  def self.for_resource(context:, resource:)
    if resource.is_a?(Class)
      Global.new(context: context, resource: resource)
    else
      Instance.new(context: context, resource: resource)
    end
  end

  class Global < Hmis::AuthPolicies::BasePolicy
    # Check if user has global permission to merge clients across any project.
    # Note: In the future, this may be need to be restricted by data source/CoC in multi-CoC installations.
    def can_merge_any_clients?
      global_permissions.include?(:can_merge_clients)
    end

    protected

    def validate_resource!(arg) = ensure_arg_class!(arg, Hmis::Hud::Client)
  end

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

    protected

    # Get permissions for the specific client instance, based on the projects they are enrolled in
    memoize def client_permissions
      context.client_permissions(resource.id)
    end

    def validate_resource!(arg) = ensure_arg_type!(arg, Hmis::Hud::Client)
  end
end
