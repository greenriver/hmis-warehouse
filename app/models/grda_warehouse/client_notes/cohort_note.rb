###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse::ClientNotes
  class CohortNote < Base
    def self.type_name
      'Cohort Note'
    end

    def destroyable_by(user)
      # Cohort notes may appear on multiple cohorts, so, only check the permissions here
      # and check the column in the controller.
      user.can_manage_cohort_data? || user.can_participate_in_cohorts?
    end
  end
end
