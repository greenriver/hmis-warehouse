###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse::SystemCohorts
  class AdultAndChild < CurrentlyHomeless
    def cohort_name
      'Adult and Child'
    end

    private def enrollment_source
      # TODO: Find all households with people only 25 or less
      GrdaWarehouse::ServiceHistoryEnrollment.entry.veterans
    end
  end
end
