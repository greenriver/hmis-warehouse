module WarehouseReports
  class FindByIdController < WarehouseReportsController
    include WarehouseReportAuthorization
    def index
      @ids = []
      @clients = []
    end

    def search
      if id_params[:id].blank?
        @clients = []
      else
        @ids = id_params[:id].strip.split(/\W+/)
        @clients = client_source.where(id: @ids).
          distinct.
          pluck(*columns).map do |row|
            Hash[columns.zip(row)]
          end
      end
      respond_to do |format|
        format.html {}
        format.xlsx do
          render xlsx: 'search', filename: 'client_details.xlsx'
        end
      end
    end

    def related_report
      GrdaWarehouse::WarehouseReports::ReportDefinition.where(url: 'warehouse_reports/find_by_id')
    end

    private def id_params
      params.require(:client)
    end
    private def columns
      [
        :id,
        :FirstName,
        :LastName,
        :SSN,
        :DOB,
        :VeteranStatus,
      ]
    end

    private def client_source
      GrdaWarehouse::Hud::Client.destination
    end

  end
end
