###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'progress_bar'
module ServiceHistory
  class RebuildEnrollmentsByBatchJob < BaseJob
    include ArelHelper
    queue_as ENV.fetch('DJ_LONG_QUEUE_NAME', :long_running)

    def initialize(enrollment_ids:, progress: false)
      @enrollment_ids = enrollment_ids
      @progress = progress
    end

    def perform
      bar = ProgressBar.new(@enrollment_ids.size, :counter, :bar, :percentage, :rate, :eta) if @progress
      Rails.logger.debug "===RebuildEnrollmentsByBatchJob=== Starting to rebuild #{@enrollment_ids.size} enrollments"

      enrollment_scope.find_each do |enrollment|
        Rails.logger.info "===RebuildEnrollmentsByBatchJob=== Processing enrollment #{enrollment.id}"
        enrollment.rebuild_service_history!
        bar&.increment!
      end
    end

    def enqueue(job, queue: ENV.fetch('DJ_LONG_QUEUE_NAME', :long_running))
    end

    def max_attempts
      2
    end

    def enrollment_scope
      GrdaWarehouse::Tasks::ServiceHistory::Enrollment.where(id: @enrollment_ids).preload(
        :destination_client,
        :project,
        :exit,
        :current_living_situations,
        :client,
        :data_source,
        :export,
        :service_history_enrollment,
        # :services,
      )
    end
  end
end
