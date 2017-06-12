module Admin::Dashboard
  class ImportsController < ApplicationController
    before_action :require_can_view_imports!
    def index
      @imports = GrdaWarehouse::DataSource.importable.map do |d|
        GrdaWarehouse::ImportLog.where(
          data_source_id: d.id
        ).select(
          :id,
          :data_source_id,
          :completed_at,
          :created_at,
          :updated_at,
          :files
        ).order('id desc').first_or_initialize
      end

      @duplicates = GrdaWarehouse::IdentifyDuplicatesLog.last
      @service_history = GrdaWarehouse::GenerateServiceHistoryLog.last
      source_clients = GrdaWarehouse::Hud::Client.source.pluck(:id)
      matched_sources = GrdaWarehouse::WarehouseClient.pluck(:source_id)

      @source_clients_with_no_destination = (source_clients - matched_sources).size
      # @service_histories_to_add =  GrdaWarehouse::Hud::Client.destination.without_service_history.count
    end

    private def client_source
      GrdaWarehouse::Hud::Client
    end

    private def warehouse_client_source
      GrdaWarehouse::WarehouseClient
    end

    private def data_source_scope
      GrdaWarehouse::DataSource.importable
    end
  end
end
