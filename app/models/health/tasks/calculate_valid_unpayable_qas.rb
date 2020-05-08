###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module Health::Tasks
  class CalculateValidUnpayableQas < ActiveJob::Base
    def run!
      # Only calculate on unsubmitted QAs to prevent changes to status after submission, and limit to 180 days
      # To avoid very old QAs
      date_range = (Date.current..Date.current - 180.days)
      Health::QualifyingActivity.unsubmitted.in_range(date_range).find_each do |qa|
        qa.update(valid_unpayable: qa.valid_unpayable?)
      end
    end
  end
end