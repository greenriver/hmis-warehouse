###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module Health::Tasks
  class CalculateValidUnpayableQas < ActiveJob::Base
    def run!
      # Only calculate on unsubmitted QAs to prevent changes to status after submission, and limit to 180 days
      # to avoid very old QAs
      date_range = (Date.current - 180.days..Date.current)
      qa_scope = Health::QualifyingActivity.joins(:patient).unsubmitted.in_range(date_range)
      qa_scope.find_each(&:maintain_valid_unpayable)
      qa_scope.find_each(&:maintain_procedure_valid)
    end
  end
end