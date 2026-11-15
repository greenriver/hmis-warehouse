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

  # for confidential organizations, is there permission to view the name
  def can_view_name?
    return true unless organization.confidential?

    name_permissions.include?(:can_edit_organizations) || name_permissions.include?(:can_view_confidential_project_names)
  end

  protected

  # ACL users need the permission from a grant on the organization or its data source. Legacy
  # users don't: a legacy user who can see a confidential project's name also sees its
  # organization's name (see ProjectPolicy#can_view_organization_name?), so Organization#name
  # checks their role permissions directly instead of masking what the project rows show.
  def name_permissions
    return resource_permissions if context.organization_name_requires_organization_grant?

    context.legacy_permissions
  end

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
