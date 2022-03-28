###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse::SystemCohorts
  class YouthNoChild < CurrentlyHomeless
    def cohort_name
      'Youth (all 18-24)'
    end

    private def enrollment_source
      # Find all households with people only 25 and no one under 18
      GrdaWarehouse::ServiceHistoryEnrollment.entry.where(client_id: youth_no_child_client_ids)
    end
  end
end
