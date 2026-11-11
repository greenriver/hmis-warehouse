###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class GrdaWarehouse::AuthPolicies::DataSourcePolicy < GrdaWarehouse::AuthPolicies::BasePolicy
  # expose role permissions. Optionally rename the permission
  [
    [:can_edit_data_sources, :can_edit?],
    [:can_delete_data_sources, :can_delete?],
    [:can_edit_projects, :can_edit_projects?],
  ].each do |permission, method_name|
    method_name ||= :"#{permission}?"
    define_method(method_name) do
      resource_permissions.include?(permission)
    end
  end

  memoize def can_see_raw_hmis_data?
    resource_permissions.include?(:can_edit_data_sources) && resource_permissions.include?(:can_upload_hud_zips)
  end

  # Import thresholds, CSV monitors, and their notification recipients. The admin alerts pages
  # check can_edit_warehouse_alerts globally, but changing one data source's alerts requires the
  # permission from a grant that covers that data source.
  memoize def can_edit_import_alerts?
    resource_permissions.include?(:can_edit_warehouse_alerts) || can_edit?
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
