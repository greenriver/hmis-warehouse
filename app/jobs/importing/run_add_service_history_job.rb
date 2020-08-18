###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Importing
  class RunAddServiceHistoryJob < BaseJob
    queue_as :long_running

    def perform
      # Refuse to run this in duplicate, it ends up hitting some race conditions and
      # generally making processing slow
      return if Delayed::Job.jobs_for_class('RunAddServiceHistoryJob').exists?

      client_ids = GrdaWarehouse::Hud::Client.destination.without_service_history.pluck(:id)
      GrdaWarehouse::Tasks::ServiceHistory::Add.new(force_sequential_processing: true).run!
      GrdaWarehouse::WarehouseClientsProcessed.update_cached_counts(client_ids: client_ids)
    end
  end
end
