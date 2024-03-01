###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# = HudSpmReport::Adapters::ServiceHistoryEnrollmentFilter
#
# Allow us to use the existing report form to filter SPM reports. Needed since the existing form filters
# ServiceHistoryEnrollments but the SPM report operates on raw HUD data
module HudSpmReport::Adapters
  class ServiceHistoryEnrollmentFilter
    include ::Filter::FilterScopes
    include ArelHelper

    def initialize(report_instance)
      spm_project_types = HudUtility2024.spm_project_type_codes
      @filter = Filters::HudFilterBase.new(user_id: report_instance.user.id, relevant_project_types: spm_project_types).update(report_instance.options)
      @project_ids = GrdaWarehouse::Hud::Project.where(id: report_instance.project_ids).pluck(:project_id)
    end

    def enrollments
      report_start_date = @filter.start
      report_end_date = @filter.end
      lookback_start_date = report_start_date - 7.years
      scope = GrdaWarehouse::ServiceHistoryEnrollment.
        joins(:client, :project).
        open_between(start_date: lookback_start_date, end_date: report_end_date).
        where(project_id: @project_ids)

      # ATTN: coc filter is needed for testkit
      scope = filter_for_cocs(scope)
      scope = @filter.apply_client_level_restrictions(scope)

      GrdaWarehouse::Hud::Enrollment.where(id: scope.joins(:enrollment).select(e_t[:id]))
    end
  end
end
