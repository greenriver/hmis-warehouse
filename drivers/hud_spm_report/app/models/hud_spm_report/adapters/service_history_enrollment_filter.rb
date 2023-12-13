###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudSpmReport::Adapters
  class ServiceHistoryEnrollmentFilter
    include ::Filter::FilterScopes
    include ArelHelper

    def initialize(filter)
      @filter = filter
    end

    def enrollments
      report_start_date = @filter.start
      report_end_date = @filter.end
      lookback_start_date = report_start_date - 7.years
      scope = GrdaWarehouse::ServiceHistoryEnrollment.
        open_between(start_date: lookback_start_date, end_date: report_end_date)
        # FIXME: effective_project_ids doesn't seem to match testkit
        # where(project_id: @filter.effective_project_ids)

      # ATTN: coc filter is needed for testkit
      scope = filter_for_cocs(scope)

      scope = filter_for_head_of_household(scope)
      scope = filter_for_age(scope)
      scope = filter_for_gender(scope)
      scope = filter_for_race(scope)
      scope = filter_for_sub_population(scope)

      GrdaWarehouse::Hud::Enrollment.where(id: scope.joins(:enrollment).select(e_t[:id]))
    end
  end
end
