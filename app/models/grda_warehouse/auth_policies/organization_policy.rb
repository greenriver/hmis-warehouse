###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class GrdaWarehouse::AuthPolicies::OrganizationPolicy < GrdaWarehouse::AuthPolicies::BasePolicy
  # expose role permissions. Optionally rename the permission
  [
    [:can_view_imports, :can_edit_contacts?],
  ].each do |permission, method_name|
    method_name ||= :"#{permission}?"
    define_method(method_name) do
      resource_permissions.include?(permission)
    end
  end

  protected

  def validate_resource!(arg)
    ensure_arg_type!(arg, GrdaWarehouse::Hud::Organization)
  end

  def resource_permissions
    context.organization_role_permissions(organization.id, organization.data_source_id)
  end

  def organization
    resource
  end
end
