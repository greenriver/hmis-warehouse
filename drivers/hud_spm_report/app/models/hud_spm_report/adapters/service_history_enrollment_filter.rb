###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudSpmReport::Adapters
  class ServiceHistoryEnrollmentFilter
    include ::Filter::FilterScopes
    include ArelHelper

    def initialize(report_instance)
      @filter = Filters::HudFilterBase.new(user_id: User.system_user.id).update(report_instance.options)
      @project_ids = GrdaWarehouse::Hud::Project.where(id: report_instance.project_ids).pluck(:project_id)
    end

    def enrollments
      report_start_date = @filter.start
      report_end_date = @filter.end
      lookback_start_date = report_start_date - 7.years
      scope = GrdaWarehouse::ServiceHistoryEnrollment.
        open_between(start_date: lookback_start_date, end_date: report_end_date).
        where(project_id: @project_ids)

      # ATTN: coc filter is needed for testkit
      scope = filter_for_cocs(scope)

      GrdaWarehouse::Hud::Enrollment.where(id: scope.joins(:enrollment).select(e_t[:id]))
    end
  end
end
