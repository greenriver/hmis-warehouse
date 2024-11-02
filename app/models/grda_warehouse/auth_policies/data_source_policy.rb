###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class GrdaWarehouse::AuthPolicies::DataSourcePolicy < GrdaWarehouse::AuthPolicies::BasePolicy
  # expose role permissions. Optionally rename the permission
  [
    [:can_edit_data_sources, :can_edit?],
  ].each do |permission, method_name|
    method_name ||= :"#{permission}?"
    define_method(method_name) do
      role_permissions.include?(permission)
    end
  end

  memoize def can_see_raw_hmis_data?
    perms.subset?(role_permissions)
  end

  protected

  def role_permissions
    context.project_role_permissions(project_id)
  end

  def data_source
    resource
  end

  def data_source_id
    resource.id
  end
end
