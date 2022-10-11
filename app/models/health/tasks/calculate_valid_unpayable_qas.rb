###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Health::Tasks
  class CalculateValidUnpayableQas < ActiveJob::Base
    def run!
      advisory_lock_key = 'calculate_valid_unpayable_qas'
      Health::QualifyingActivity.with_advisory_lock(advisory_lock_key, timeout_seconds: 0) do
        # Only calculate on unsubmitted QAs to prevent changes to status after submission, and limit to 180 days
        # to avoid very old QAs
        date_range = (Date.current - 180.days..Date.current)
        qa_scope = Health::QualifyingActivity.joins(:patient).unsubmitted.in_range(date_range).order(date_of_activity: :asc)
        qa_scope.find_each(&:maintain_cached_values)
      end
    end
  end
end
