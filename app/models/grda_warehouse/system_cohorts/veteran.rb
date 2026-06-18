###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module GrdaWarehouse::SystemCohorts
  class Veteran < CurrentlyHomeless
    def cohort_name
      'Veterans'
    end

    private def enrollment_source
      GrdaWarehouse::ServiceHistoryEnrollment.entry.veterans
    end
  end
end
