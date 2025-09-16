###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class ClientCleanupJob < BaseJob
  queue_as ENV.fetch('DJ_LONG_QUEUE_NAME', :long_running)
  queue_with_priority 6

  WAIT_MINUTES = 1

  def perform(ids)
    running_jobs = Delayed::Job.jobs_for_class('ClientCleanupJob').running.count
    # allow up to 2 jobs to run at once, to avoid overwhelming the workers
    if running_jobs > 1

      requeue_at(Time.current + WAIT_MINUTES.minutes, "ClientCleanupJob already running...re-queuing job for #{WAIT_MINUTES} minutes from now")
      return
    end

    GrdaWarehouse::Tasks::ClientCleanup.run_for_clients(ids)
  end

  def priority
    6
  end
end
