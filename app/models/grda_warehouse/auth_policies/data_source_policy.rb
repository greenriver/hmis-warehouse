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
      resource_permissions.include?(permission)
    end
  end

  memoize def can_see_raw_hmis_data?
    resource_permissions.include?(:can_edit_data_sources) && resource_permissions.include?(:can_upload_hud_zips)
  end

  protected

  def validate_resource!(arg)
    ensure_arg_type!(arg, GrdaWarehouse::DataSource)
  end

  def resource_permissions
    context.data_source_role_permissions(data_source_id)
  end

  def data_source
    resource
  end

  def data_source_id
    resource.id
  end
end
