###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse::SystemCohorts
  class Youth < CurrentlyHomeless
    def cohort_name
      'Youth (under 25)'
    end

    private def enrollment_source
      # TODO: Find all households with people only 25 or less
      GrdaWarehouse::ServiceHistoryEnrollment.entry.where(client_id: youth_only_client_ids)
    end
  end
end
