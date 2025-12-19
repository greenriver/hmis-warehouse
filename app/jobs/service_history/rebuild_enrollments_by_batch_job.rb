###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module ServiceHistory
  class RebuildEnrollmentsByBatchJob < BaseJob
    include ArelHelper
    queue_as ENV.fetch('DJ_LONG_QUEUE_NAME', :long_running)

    def initialize(enrollment_ids:)
      @enrollment_ids = enrollment_ids
    end

    def perform
      Rails.logger.debug "===RebuildEnrollmentsByBatchJob=== Starting to rebuild #{@enrollment_ids.size} enrollments"

      @enrollment_ids.each do |id|
        Rails.logger.info "===RebuildEnrollmentsByBatchJob=== Processing enrollment #{id}"
        # Rails.logger.debug "rebuilding enrollment #{enrollment_id}"
        GrdaWarehouse::Tasks::ServiceHistory::Enrollment.
          where(id: id).
          each(&:rebuild_service_history!)
      end
    end

    def enqueue(job, _queue: ENV.fetch('DJ_LONG_QUEUE_NAME', :long_running))
      job.priority = BaseJob::NO_RUSH_PRIORITY - 1
    end

    def max_attempts
      2
    end
  end
end
