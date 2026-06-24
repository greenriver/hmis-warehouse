###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class UpdateWarehouseClientsCachesJob < BaseJob
  queue_as ENV.fetch('DJ_LONG_QUEUE_NAME', :long_running)
  WAIT_MINUTES = 4
  ADVISORY_LOCK_NAME = 'UpdateWarehouseClientsCachesJob'

  def perform(client_ids: [], include_cas_and_cohorts: false, skip_expensive_calculations: false)
    # If any for this class are already running, requeue for a few minutes in the future
    lock_obtained = nil
    GrdaWarehouse::WarehouseClientsProcessed.with_advisory_lock(ADVISORY_LOCK_NAME, timeout_seconds: 20) do
      GrdaWarehouse::WarehouseClientsProcessed.update_cached_counts(client_ids: client_ids, include_cas_and_cohorts: include_cas_and_cohorts, skip_expensive_calculations: skip_expensive_calculations)
      lock_obtained = true
    end

    requeue_at(Time.current + WAIT_MINUTES.minutes, "UpdateWarehouseClientsCachesJob is already running...re-queuing job for #{WAIT_MINUTES} minutes from now") unless lock_obtained
  end
end
