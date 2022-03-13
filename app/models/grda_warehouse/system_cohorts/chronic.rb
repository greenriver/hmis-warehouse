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
      # Find all clients who are enrolled in a project indicating chronic at entry (for the current date)
      clients = GrdaWarehouse::Hud::Client.destination.joins(source_enrollments: :ch_enrollment).
        merge(GrdaWarehouse::ChEnrollment.chronically_homeless)
      GrdaWarehouse::ServiceHistoryEnrollment.entry.where(client_id: clients.distinct.select(:id))
    end
  end
end
