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

      clear_processing_job_id
    end

    def enqueue(job)
      job.priority = BaseJob::PRE_BULK_PROCESSING_PRIORITY_9
    end

    # DJ calls this only after all max_attempts are exhausted (failed_at is set at that point).
    # Between retries, failed_at remains nil, so the job stays in the active_job_ids set
    # used by wait_for_processing / clients_still_processing? — enrollment stamps are correctly
    # treated as in-progress until the retry either succeeds or permanently fails.
    def failure(_job)
      clear_processing_job_id
    end

    def max_attempts
      2
    end

    private

    def clear_processing_job_id
      GrdaWarehouse::Hud::Enrollment.where(id: @enrollment_ids).
        update_all(service_history_processing_job_id: nil)
    end
  end
end
