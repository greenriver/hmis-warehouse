module WarehouseReports
  class AnomaliesController < ApplicationController
    include WarehouseReportAuthorization
    include ArelHelper

    def index
      @new = anomaly_source.newly_minted.order(created_at: :asc).preload(:client, :user)
      @unresolved = anomaly_source.unresolved.order(created_at: :asc).preload(:client, :user)
      @resolved = anomaly_source.resolved.order(created_at: :asc).preload(:client, :user)
    end

    def anomaly_source
      GrdaWarehouse::Anomaly
    end
  end
end
