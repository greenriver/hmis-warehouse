###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class GrdaWarehouse::AuthPolicies::DataQualityReportPolicy < GrdaWarehouse::AuthPolicies::BasePolicy
  REPORT_DEFINITION_URL = 'warehouse_reports/project/data_quality'

  def can_view?
    report_definition_viewable? && subject_viewable?
  end

  protected

  def validate_resource!(arg)
    ensure_arg_type!(arg, GrdaWarehouse::WarehouseReports::Project::DataQuality::Base)
  end

  memoize def report_definition_viewable?
    GrdaWarehouse::WarehouseReports::ReportDefinition.where(url: REPORT_DEFINITION_URL).viewable_by(user).exists?
  end

  memoize def subject_viewable?
    if resource.project_group_id.present?
      GrdaWarehouse::ProjectGroup.viewable_by(user).where(id: resource.project_group_id).exists?
    else
      GrdaWarehouse::Hud::Project.viewable_by(user).where(id: resource.project_id).exists?
    end
  end
end
