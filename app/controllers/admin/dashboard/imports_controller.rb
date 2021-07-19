###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Admin::Dashboard
  class ImportsController < ApplicationController
    before_action :require_can_view_imports!
    def index
      sti_col = GrdaWarehouse::ImportLog.inheritance_column
      GrdaWarehouse::ImportLog.inheritance_column = :_disabled
      @imports = data_source_scope.map do |d|
        GrdaWarehouse::ImportLog.where(data_source_id: d.id).
          diet.
          order(id: :desc).first_or_initialize
      end

      @duplicates = GrdaWarehouse::IdentifyDuplicatesLog.last
      @service_history = GrdaWarehouse::GenerateServiceHistoryLog.last
      source_clients = client_scope.pluck(:id)
      matched_sources = warehouse_client_source.pluck(:source_id)

      @source_clients_with_no_destination = (source_clients - matched_sources).size
    ensure
      GrdaWarehouse::ImportLog.inheritance_column = sti_col
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
