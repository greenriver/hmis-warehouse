###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class UpdateWarehouseClientsCachesJob < BaseJob
  queue_as ENV.fetch('DJ_LONG_QUEUE_NAME', :long_running)
  WAIT_MINUTES = 4

  def perform(client_ids: [], include_cas_and_cohorts: false, skip_expensive_calculations: false)
    # If any for this class are already running, requeue for a few minutes in the future
    lock_obtained = GrdaWarehouse::WarehouseClientsProcessed.with_advisory_lock('UpdateWarehouseClientsCachesJob', timeout_seconds: 20) do
      GrdaWarehouse::WarehouseClientsProcessed.update_cached_counts(client_ids: client_ids, include_cas_and_cohorts: include_cas_and_cohorts, skip_expensive_calculations: skip_expensive_calculations)
    end

    requeue_at(Time.current + WAIT_MINUTES.minutes, "UpdateWarehouseClientsCachesJob is already running...re-queuing job for #{WAIT_MINUTES} minutes from now") if lock_obtained == false
  end
end
