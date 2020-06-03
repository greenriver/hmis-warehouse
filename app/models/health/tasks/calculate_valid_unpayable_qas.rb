###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module Health::Tasks
  class CalculateValidUnpayableQas < ActiveJob::Base
    def run!
      advisory_lock_key = 'calculate_valid_unpayable_qas'
      return if Health::QualifyingActivity.advisory_lock_exists?(advisory_lock_key)

      Health::QualifyingActivity.with_advisory_lock(advisory_lock_key) do
        # Only calculate on unsubmitted QAs to prevent changes to status after submission, and limit to 180 days
        # to avoid very old QAs
        date_range = (Date.current - 180.days..Date.current)
        qa_scope = Health::QualifyingActivity.joins(:patient).unsubmitted.in_range(date_range)
        qa_scope.find_each do |qa|
          qa.maintain_valid_unpayable
          qa.maintain_procedure_valid
        end
      end
    end
  end
end