###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse::SystemCohorts
  class Chronic < CurrentlyHomeless
    include ArelHelper

    def cohort_name
      'Chronic'
    end

    private def enrollment_source
      # Find all clients who are enrolled in a project indicating chronic at entry (for the current date)
      # Only include CH HoH and adults, and any children in households where that is true
      adult_ids = GrdaWarehouse::Hud::Client.destination.joins(source_enrollments: :ch_enrollment).
        age_group(start_age: 18).
        merge(GrdaWarehouse::ChEnrollment.chronically_homeless).
        merge(GrdaWarehouse::Hud::Enrollment.open_on_date(@processing_date)).
        pluck(:id, e_t[:HouseholdID])
      hoh_ids = GrdaWarehouse::Hud::Client.destination.joins(source_enrollments: :ch_enrollment).
        merge(GrdaWarehouse::Hud::Enrollment.heads_of_households).
        merge(GrdaWarehouse::ChEnrollment.chronically_homeless).
        merge(GrdaWarehouse::Hud::Enrollment.open_on_date(@processing_date)).
        pluck(:id, e_t[:HouseholdID])
      children_ids = GrdaWarehouse::Hud::Client.destination.joins(source_enrollments: :ch_enrollment).
        age_group(start_age: 0, end_age: 17).
        merge(GrdaWarehouse::Hud::Enrollment.open_on_date(@processing_date).where(HouseholdID: adult_ids.map(&:last) + hoh_ids.map(&:last))).
        pluck(:id)
      GrdaWarehouse::ServiceHistoryEnrollment.entry.where(client_id: adult_ids.map(&:first) + hoh_ids.map(&:first) + children_ids)
    end
  end
end
