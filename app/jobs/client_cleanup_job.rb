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
    lock_obtained = nil
    with_advisory_lock('client_cleanup_job', timeout_seconds: 0) do
      GrdaWarehouse::Tasks::ClientCleanup.run_for_clients(ids)
      lock_obtained = true
    end
    requeue_at(Time.current + WAIT_MINUTES.minutes, "ClientCleanupJob already running...re-queuing job for #{WAIT_MINUTES} minutes from now") unless lock_obtained
  end

  def priority
    6
  end
end
