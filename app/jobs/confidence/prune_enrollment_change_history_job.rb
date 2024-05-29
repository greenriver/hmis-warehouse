###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Confidence
  class PruneEnrollmentChangeHistoryJob < BaseJob
    queue_as ENV.fetch('DJ_LONG_QUEUE_NAME', :long_running)

    def perform(date:)
      # date will be string when deserialized from the job runner
      date = date.to_date
      pruned = GrdaWarehouse::EnrollmentChangeHistory.expired_as_of(date).delete_all
      # vacuum full to recover disk space. Locks table exclusively until complete
      GrdaWarehouse::EnrollmentChangeHistory.vacuum_table(full_with_lock: true)
      pruned
    end

    def max_attempts
      1
    end
  end
end
