###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# The tool has its own definition and run rule (`visible_to`), unlike HUD runs.
module HmisDataQualityTool
  class ReportPolicy < GrdaWarehouse::AuthPolicies::HudReportPolicy
    memoize def can_view_definition?
      GrdaWarehouse::WarehouseReports::ReportDefinition.url_viewable_by?(HmisDataQualityTool::Report.url, user)
    end

    memoize def run_visible?
      HmisDataQualityTool::Report.visible_to(user).where(id: resource.id).exists?
    end

    protected

    def validate_resource!(arg)
      ensure_arg_type!(arg, HmisDataQualityTool::Report)
    end
  end
end
