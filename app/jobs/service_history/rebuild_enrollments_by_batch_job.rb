###
# Copyright 2016 - 2019 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module ServiceHistory
  class RebuildEnrollmentsByBatchJob < BaseJob
    include ArelHelper
    queue_as :low_priority

    def initialize(enrollment_ids:)
      @enrollment_ids = enrollment_ids
    end

    def perform
      Rails.logger.debug "===RebuildEnrollmentsByBatchJob=== Starting to rebuild #{@enrollment_ids.size} enrollments"

      @enrollment_ids.each do |id|
        Rails.logger.info "===RebuildEnrollmentsByBatchJob=== Processing enrollment #{id}"
        # Rails.logger.debug "rebuilding enrollment #{enrollment_id}"
        enrollment = GrdaWarehouse::Tasks::ServiceHistory::Enrollment.find(id)
        enrollment.rebuild_service_history!
      end
    end

    def enqueue(job, queue: :low_priority); end

    def max_attempts
      2
    end
  end
end
