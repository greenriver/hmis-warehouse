###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module GrdaWarehouse::SystemCohorts
  class Youth < CurrentlyHomeless
    def cohort_name
      'Youth (under 25)'
    end

    private def enrollment_source
      # Find all households with people only 25 or less
      GrdaWarehouse::ServiceHistoryEnrollment.entry.where(client_id: youth_only_client_ids)
    end
  end
end
