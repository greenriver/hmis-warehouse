###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse::SystemCohorts
  class YouthAndChild < CurrentlyHomeless
    def cohort_name
      'Youth and Child (Youth families)'
    end

    private def enrollment_source
      # Find all households with people only 25 or less with at least one over 18 and one under 18
      GrdaWarehouse::ServiceHistoryEnrollment.entry.where(client_id: youth_and_child_client_ids)
    end
  end
end
