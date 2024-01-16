###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse::SystemCohorts
  class ChronicIndividual < Chronic
    include ArelHelper

    def cohort_name
      'Chronic Individual'
    end

    private def enrollment_source
      GrdaWarehouse::ServiceHistoryEnrollment.
        entry.ongoing(on_date: @processing_date).
        where(
          presented_as_individual: true,
          id: GrdaWarehouse::ChEnrollment.chronically_homeless.select(:enrollment_id),
        )
    end
  end
end
