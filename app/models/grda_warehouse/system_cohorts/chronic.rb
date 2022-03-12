###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse::SystemCohorts
  class Chronic < CurrentlyHomeless
    def cohort_name
      'Chronic'
    end

    private def enrollment_source
      # TODO: Find all clients who are enrolled in a project indicating chronic at entry (for the current date)
      GrdaWarehouse::ServiceHistoryEnrollment.entry.veterans
    end
  end
end
