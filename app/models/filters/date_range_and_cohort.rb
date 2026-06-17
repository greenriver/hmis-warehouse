###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Filters
  class DateRangeAndCohort < DateRange
    attribute :cohort_id, Integer

    def available_cohorts_for(user)
      GrdaWarehouse::Cohort.active.viewable_by(user)
    end
  end
end
