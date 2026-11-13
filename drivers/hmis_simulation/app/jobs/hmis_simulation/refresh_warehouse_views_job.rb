###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HmisSimulation
  # Deferred warehouse view refresh enqueued by WarehouseSyncer after a
  # simulation run. Refreshes the service history materialized view and
  # updates cached counts for the affected destination clients.
  class RefreshWarehouseViewsJob < BaseJob
    queue_as ENV.fetch('DJ_LONG_QUEUE_NAME', :long_running)

    def perform(destination_ids:)
      GrdaWarehouse::ServiceHistoryServiceMaterialized.refresh!
      GrdaWarehouse::WarehouseClientsProcessed.update_cached_counts(client_ids: destination_ids)
    end
  end
end
