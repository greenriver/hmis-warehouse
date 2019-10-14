###
# Copyright 2016 - 2019 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module Importing
  class RunAddServiceHistoryJob < BaseJob
    queue_as :low_priority

    def perform
      client_ids = GrdaWarehouse::Hud::Client.destination.without_service_history.pluck(:id)
      GrdaWarehouse::Tasks::ServiceHistory::Add.new(force_sequential_processing: true).run!
      GrdaWarehouse::WarehouseClientsProcessed.update_cached_counts(client_ids: client_ids)
    end
  end
end
