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
      GrdaWarehouse::ServiceHistoryEnrollment.entry.where(client_id: adult_only_client_ids)
    end
  end
end
