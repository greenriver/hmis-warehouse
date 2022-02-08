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

    # only destroyable by admins for now
    def destroyable_by(user)
      user.can_edit_cohort_clients? || user.can_manage_cohorts? # || user_id == user.id
    end
  end
end
