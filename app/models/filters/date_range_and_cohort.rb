module Filters
  class DateRangeAndCohort < DateRange
    attribute :cohort_id, Integer

    def available_cohorts_for(user)
      GrdaWarehouse::Cohort.active.viewable_by(user)
    end
  end
end