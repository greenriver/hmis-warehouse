###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse::SystemCohorts
  class Veteran < CurrentlyHomeless
    def cohort_name
      'Veterans'
    end

    private def enrollment_source
      GrdaWarehouse::ServiceHistoryEnrollment.entry.veterans
    end
  end
end
