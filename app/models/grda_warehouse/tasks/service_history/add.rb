###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse::Tasks::ServiceHistory
  # A simplified version of Generate service history that only does
  # the add section.
  # This allows us to invalidate clients and relatively quickly rebuild
  # their service history
  class Add < Base
    include TsqlImport
    include ActiveSupport::Benchmarkable
    attr_accessor :logger

    def run!
      @client_ids = destination_client_scope.without_service_history.pluck(:id)
      if @client_ids.empty?
        logger.info "Nothing to do."
        return
      end
      process
      GrdaWarehouse::WarehouseClientsProcessed.update_cached_counts(client_ids: @client_ids)
    end

    def clients_needing_update_count
      destination_client_scope.without_service_history.count
    end
  end
end
