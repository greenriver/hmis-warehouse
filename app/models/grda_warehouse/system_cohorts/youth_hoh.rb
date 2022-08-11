###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse::SystemCohorts
  class YouthHoH < CurrentlyHomeless
    def cohort_name
      'Youth (under 25) and Head of Household'
    end

    private def enrollment_source
      GrdaWarehouse::ServiceHistoryEnrollment.entry.where(client_id: youth_and_hoh_client_ids)
    end
  end
end
