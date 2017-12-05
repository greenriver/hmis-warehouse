module WarehouseReports
  class LongStandingClientsController < ApplicationController
    include WarehouseReportAuthorization
    def index
      # using date instead of first_date_in_program below because it is indexed 
      # and is identical on entry records
      @years = (params[:years] || 5).to_i
      st = service_history_source.arel_table
      @entries = service_history_source.
        select(:first_date_in_program, :last_date_in_program, :client_id, :project_name).
        where( st[:date].lteq @years.years.ago ).
        where(last_date_in_program: nil).
        es.
        order(date: :asc).
        page(params[:page]).per(25)
      @clients = client_source.where(id: @entries.map(&:client_id)).preload(source_clients: :data_source).index_by(&:id)
      
    end

    private def client_source
      GrdaWarehouse::Hud::Client.destination
    end

    private def service_history_source
      GrdaWarehouse::ServiceHistory.entry
    end

    private def data_source_source
      GrdaWarehouse::DataSource.importable
    end
  end
end
