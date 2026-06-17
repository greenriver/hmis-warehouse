###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module GrdaWarehouse::SystemCohorts
  class AdultAndChild < CurrentlyHomeless
    def cohort_name
      'Adult and Child'
    end

    private def enrollment_source
      GrdaWarehouse::ServiceHistoryEnrollment.entry.where(client_id: adult_and_child_client_ids)
    end
  end
end
