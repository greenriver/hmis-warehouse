###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module Health
  class CheckPatientEligibilityJob < ActiveJob::Base
    def perform(eligibility_date_string, owner_id, user_id)
      eligibility_date = Date.parse(eligibility_date_string)
      task = Health::Tasks::CheckPatientEligibility.new
      user = User.find(user_id)
      # TODO: Determine a reasonable batch size
      task.check(eligibility_date, batch_size: 100, owner_id: owner_id, user: user, test: !Rails.env.production?)
    end
  end
end
