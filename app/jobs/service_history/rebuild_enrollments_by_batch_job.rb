###
# Copyright Green River Data Group, Inc.
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
        rebuild_one(id)
      end
    end

    private def rebuild_one(id)
      enrollment = GrdaWarehouse::Tasks::ServiceHistory::Enrollment.find_by(id: id)
      return unless enrollment

      enrollment.rebuild_service_history!
      enrollment.update_column(:processing_error, nil) if enrollment.processing_error.present?
    rescue StandardError => e
      Rails.logger.error "===RebuildEnrollmentsByBatchJob=== Enrollment #{id} failed: #{e.class}: #{e.message}"
      enrollment&.update_column(:processing_error, "#{e.class}: #{e.message}")
      Sentry.capture_exception_with_info(e, "RebuildEnrollmentsByBatchJob failed for enrollment #{id}", { enrollment_id: id })
    end

    def enqueue(job)
      job.priority = BaseJob::PRE_BULK_PROCESSING_PRIORITY_9
    end

    def max_attempts
      2
    end
  end
end
