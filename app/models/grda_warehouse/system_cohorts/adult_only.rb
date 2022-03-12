###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse::SystemCohorts
  class AdultOnly < CurrentlyHomeless
    def cohort_name
      'Adult Only'
    end

    private def enrollment_source
      # TODO: Find all households with people only 18 or older
      GrdaWarehouse::ServiceHistoryEnrollment.entry.veterans
    end
  end
end
