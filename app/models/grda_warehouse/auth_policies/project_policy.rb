###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class GrdaWarehouse::AuthPolicies::ProjectPolicy < GrdaWarehouse::AuthPolicies::BasePolicy
  # expose role permissions. Optionally rename the permission
  [
    [:can_edit_projects, :can_edit?],
    [:can_delete_projects, :can_delete?],
    [:can_view_projects, :can_view?],
    [:can_view_imports],
    [:can_view_clients],
  ].each do |permission, method_name|
    method_name ||= :"#{permission}?"
    define_method(method_name) do
      resource_permissions.include?(permission)
    end
  end

  # delegate to the project's data source
  def can_see_raw_hmis_data?
    data_source_permissions = context.data_source_role_permissions(project.data_source_id)
    data_source_permissions.include?(:can_edit_data_sources) && data_source_permissions.include?(:can_upload_hud_zips)
  end

  # can the user see the project locations (on a map)
  memoize def can_view_project_locations?
    return false unless RailsDrivers.loaded.include?(:client_location_history)

    resource_permissions.include?(:can_view_project_locations)
  end

  # for confidential projects, is there permission to view the name
  def can_view_name?
    return false unless resource_permissions.include?(:can_view_projects)
    return true unless project.confidential?

    resource_permissions.include?(:can_edit_projects) || resource_permissions.include?(:can_view_confidential_project_names)
  end

  protected

  def validate_resource!(arg)
    ensure_arg_type!(arg, GrdaWarehouse::Hud::Project)
  end

  def resource_permissions
    context.project_role_permissions(project_id)
  end

  def project
    resource
  end

  def project_id
    resource.id
  end
end
