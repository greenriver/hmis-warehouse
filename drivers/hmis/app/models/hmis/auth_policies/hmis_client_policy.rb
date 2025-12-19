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

  def can_manage_client_files? # todo @martha
    client_permissions.include?(:can_manage_any_client_files) || client_permissions.include?(:can_manage_own_client_files)
  end

  def can_manage_any_client_files?
    client_permissions.include?(:can_manage_any_client_files)
  end

  def can_merge?
    client_permissions.include?(:can_merge_clients)
  end

  protected

  memoize def client_permissions
    if resource.is_a?(Class)
      # Class-level policy (e.g., for merge operations)
      context.potential_permissions
    else
      # Instance-level policy (for a specific client)
      context.client_permissions(resource.id)
    end
  end

  def validate_resource!(arg) = ensure_arg_type!(arg, Hmis::Hud::Client)
end
