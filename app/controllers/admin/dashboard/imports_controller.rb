module Admin::Dashboard
  class ImportsController < ApplicationController
    before_action :require_can_view_imports!
    def index
      @imports = data_source_scope.map do |d|
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

      if can_edit_anything_super_user?
        @duplicates = GrdaWarehouse::IdentifyDuplicatesLog.last
        @service_history = GrdaWarehouse::GenerateServiceHistoryLog.last
        source_clients = client_scope.pluck(:id)
        matched_sources = warehouse_client_source.pluck(:source_id)

        @source_clients_with_no_destination = (source_clients - matched_sources).size
      end

    end

    private def client_scope
      client_source.source
    end

    private def client_source
      GrdaWarehouse::Hud::Client
    end

    private def warehouse_client_source
      GrdaWarehouse::WarehouseClient
    end

    private def data_source_scope
      GrdaWarehouse::DataSource.importable.viewable_by(current_user)
    end
  end
end
