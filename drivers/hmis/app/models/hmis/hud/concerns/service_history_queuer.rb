###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Hmis::Hud::Concerns::ServiceHistoryQueuer
  extend ActiveSupport::Concern

  included do
    # Queue up service history enrollment job. This should happen when certain HUD records change.
    #
    # If job is already queued, do nothing
    # If job is currently running, queue it to run 5 minutes from now.
    # Otherwise, queue the job.
    def self.queue_service_history_processing!
      handlers = ['GrdaWarehouse::Tasks::ServiceHistory::Enrollment', 'batch_process_unprocessed!']
      return if Delayed::Job.queued?(handlers)

      currently_running = Delayed::Job.running?(handlers)
      run_at = currently_running ? 5.minutes.from_now : nil
      queue = ENV.fetch('DJ_LONG_QUEUE_NAME', :long_running)
      GrdaWarehouse::Tasks::ServiceHistory::Enrollment.delay(priority: 12, run_at: run_at, queue: queue).batch_process_unprocessed!
    end

    def queue_service_history_processing!
      self.class.queue_service_history_processing!
    end
  end
end
