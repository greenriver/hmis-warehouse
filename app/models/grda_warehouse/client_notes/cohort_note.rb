###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse::ClientNotes
  class CohortNote < Base
    def self.type_name
      'Cohort Note'
    end

    def destroyable_by(user)
      user.can_manage_cohort_data? && user.can_participate_in_cohorts?
    end
  end
end
