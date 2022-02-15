###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Filters
  class DateRangeAndCohort < DateRange
    attribute :cohort_id, Integer

    def available_cohorts_for(user)
      GrdaWarehouse::Cohort.active.viewable_by(user)
    end
  end
end
