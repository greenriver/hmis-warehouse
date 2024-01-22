###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse::SystemCohorts
  class ChronicAdultOnly < CurrentlyHomeless
    include ArelHelper

    def cohort_name
      'Chronic Adult-Only Household'
    end

    private def enrollment_source
      # Find the client ids for CH adults on the processing date
      adult_ids = GrdaWarehouse::Hud::Client.destination.joins(source_enrollments: :ch_enrollment).
        age_group(start_age: 18).
        merge(GrdaWarehouse::ChEnrollment.chronically_homeless).
        merge(GrdaWarehouse::Hud::Enrollment.open_on_date(@processing_date)).
        pluck(:id)

      GrdaWarehouse::ServiceHistoryEnrollment.
        where(client_id: adult_only_client_ids & adult_ids) # if a a client is in an adult-only household, and is a CH adult, include their enrollments
    end
  end
end
