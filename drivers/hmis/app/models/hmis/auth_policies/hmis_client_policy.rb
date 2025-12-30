###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class Hmis::AuthPolicies::HmisClientPolicy < Hmis::AuthPolicies::BasePolicy
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

  # Check if user has global permission to merge clients across any project.
  # Note: In the future, this may be need to be restricted by data source/CoC in multi-CoC installations.
  def can_merge_any_clients?
    global_permissions.include?(:can_merge_clients)
  end

  protected

  # Get permissions for the specific client instance, based on the projects they are enrolled in
  memoize def client_permissions
    # SAFETY: Require client instance to prevent accidental global permission checks.
    #   Wrong: policy_for(Hmis::Hud::Client, :hmis_client).can_destroy? (uses global permissions)
    #   Right: policy_for(client_instance, :hmis_client).can_destroy? (uses instance permissions)
    #   For global checks: add separate methods like can_destroy_any_clients?
    raise ArgumentError, 'Must provide a client instance' unless resource.is_a?(Hmis::Hud::Client)

    context.client_permissions(resource.id)
  end

  # Get global permissions for the user (across all projects they can access)
  # These can be accessed when the policy is instantiated with a class
  def global_permissions
    context.global_permissions
  end

  def validate_resource!(arg) = ensure_arg_type!(arg, Hmis::Hud::Client)
end
